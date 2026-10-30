'use strict';
// Item icons for the Bank tab. The local host reads them from the game's own interface.fdb, in a format a
// page can't show, so they are decoded here and kept as PNG data URLs. Nothing leaves this PC.
const GBIcons = (() => {
  const CACHE = 'icon:';
  const BATCH = 20;

  function color565(value) {
    return [((value >> 11) & 31) * 255 / 31, ((value >> 5) & 63) * 255 / 63, (value & 31) * 255 / 31];
  }
  function colorBlock(view, at, pixels, width, x, y, fourColors) {
    const c0 = view.getUint16(at, true), c1 = view.getUint16(at + 2, true);
    const a = color565(c0), b = color565(c1);
    const palette = [a, b];
    if (fourColors || c0 > c1) {
      palette.push(a.map((v, i) => (2 * v + b[i]) / 3), a.map((v, i) => (v + 2 * b[i]) / 3));
    } else {
      palette.push(a.map((v, i) => (v + b[i]) / 2), [0, 0, 0]);
    }
    let bits = view.getUint32(at + 4, true);
    const transparent = !fourColors && c0 <= c1;
    for (let row = 0; row < 4; row++) {
      for (let col = 0; col < 4; col++) {
        const index = bits & 3;
        bits >>>= 2;
        const out = ((y + row) * width + x + col) * 4;
        if (out + 3 >= pixels.length || x + col >= width) continue;
        pixels[out] = palette[index][0];
        pixels[out + 1] = palette[index][1];
        pixels[out + 2] = palette[index][2];
        pixels[out + 3] = transparent && index === 3 ? 0 : 255;
      }
    }
  }
  function alphaBlock(view, at, pixels, width, x, y) {
    const a0 = view.getUint8(at), a1 = view.getUint8(at + 1);
    const table = [a0, a1];
    if (a0 > a1) for (let i = 1; i < 7; i++) table.push(((7 - i) * a0 + i * a1) / 7);
    else { for (let i = 1; i < 5; i++) table.push(((5 - i) * a0 + i * a1) / 5); table.push(0, 255); }
    const low = view.getUint8(at + 2) | view.getUint8(at + 3) << 8 | view.getUint8(at + 4) << 16;
    const high = view.getUint8(at + 5) | view.getUint8(at + 6) << 8 | view.getUint8(at + 7) << 16;
    for (let row = 0; row < 4; row++) {
      const bits = row < 2 ? low : high;
      for (let col = 0; col < 4; col++) {
        const shift = (row % 2) * 12 + col * 3;
        const out = ((y + row) * width + x + col) * 4;
        if (out + 3 < pixels.length && x + col < width) pixels[out + 3] = table[(bits >> shift) & 7];
      }
    }
  }
  // A picture as interface.fdb stores it: format, width, height and mip count as 32-bit numbers, then the
  // largest picture. Format 4 is BGRA, 6 is DXT1, 8 is DXT5. Returns null for anything else.
  function decode(bytes) {
    if (bytes.length < 16) return null;
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    const format = view.getUint32(0, true), width = view.getUint32(4, true), height = view.getUint32(8, true);
    if (!width || !height || width > 1024 || height > 1024) return null;
    const pixels = new Uint8ClampedArray(width * height * 4);
    let at = 16;
    if (format === 4) {
      if (at + width * height * 4 > bytes.length) return null;
      for (let i = 0; i < width * height; i++, at += 4) {
        pixels[i * 4] = bytes[at + 2];
        pixels[i * 4 + 1] = bytes[at + 1];
        pixels[i * 4 + 2] = bytes[at];
        pixels[i * 4 + 3] = bytes[at + 3];
      }
      return {width, height, pixels};
    }
    if (format !== 6 && format !== 8) return null;
    const size = format === 6 ? 8 : 16;
    for (let y = 0; y < height; y += 4) {
      for (let x = 0; x < width; x += 4, at += size) {
        if (at + size > bytes.length) return null;
        colorBlock(view, at + size - 8, pixels, width, x, y, format === 8);
        if (format === 8) alphaBlock(view, at, pixels, width, x, y);
      }
    }
    return {width, height, pixels};
  }
  function toDataUrl(picture) {
    const canvas = document.createElement('canvas');
    canvas.width = picture.width;
    canvas.height = picture.height;
    canvas.getContext('2d').putImageData(new ImageData(picture.pixels, picture.width, picture.height), 0, 0);
    return canvas.toDataURL('image/png');
  }
  function fromBase64(text) {
    const binary = atob(text);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
  }
  // Fetches what isn't cached yet, a batch at a time, and calls show(name, url) for each icon as it arrives.
  async function load(names, send, show) {
    const unique = [...new Set(names.filter(Boolean))];
    const keys = unique.map(name => CACHE + name.toLowerCase());
    const cached = await chrome.storage.local.get(keys);
    const missing = [];
    unique.forEach((name, i) => {
      if (cached[keys[i]]) show(name, cached[keys[i]]);
      else missing.push(name);
    });
    while (missing.length) {
      const batch = missing.splice(0, BATCH);
      const response = await send({type: 'bank-icons', names: batch});
      if (Array.isArray(response.later)) missing.push(...response.later);
      const store = {};
      for (const [name, data] of Object.entries(response.icons || {})) {
        // The local host sends base64, folders.js the bytes themselves.
        const picture = decode(typeof data === 'string' ? fromBase64(data) : data);
        if (!picture) continue;
        const url = toDataUrl(picture);
        store[CACHE + name.toLowerCase()] = url;
        show(name, url);
      }
      // A full cache only means icons are read again next time.
      await chrome.storage.local.set(store).catch(() => {});
    }
  }
  return {decode, load};
})();
