"""Runtime art bounds/alpha and preservation of supplied resource masters."""
from pathlib import Path
import hashlib,json,struct,unittest

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'design/rwa-resource-assets-v1'
RUNTIME=ROOT/'Interface/AddOns/CherrysKit/RomWeakAuras/Media/Textures/Resources'

class ResourceAssetTests(unittest.TestCase):
    def test_supplied_masters_and_references_are_unchanged(self):
        manifest=json.loads((ART/'asset_manifest.json').read_text())
        for item in manifest['files']:
            with self.subTest(file=item['path']):
                self.assertEqual(hashlib.sha256((ART/item['path']).read_bytes()).hexdigest(),item['sha256'])

    def test_native_exports_have_expected_dimensions_rgba_and_transparent_edges(self):
        expected={'soul-diamond':(64,64),'max-label':(256,128),'bar-frame-metal':(512,64),
                  'bar-fill-bevel':(256,32),'bar-fill-glass':(256,32)}
        for name,size in expected.items():
            with self.subTest(asset=name):
                data=(RUNTIME/(name+'.tga')).read_bytes()
                self.assertEqual(data[2],2) # uncompressed true-colour
                self.assertEqual(data[16],32)
                self.assertEqual(data[17]&15,8)
                w,h=struct.unpack('<HH',data[12:16])
                self.assertEqual((w,h),size)
                pixels=data[18+data[0]:18+data[0]+w*h*4]
                alpha=pixels[3::4]
                self.assertEqual((min(alpha),max(alpha)),(0,255))
                self.assertTrue(any(0<a<255 for a in alpha))
                self.assertTrue(all(a==0 for a in alpha[:w]))
                self.assertTrue(all(a==0 for a in alpha[-w:]))
                self.assertTrue(all(alpha[y*w]==0 and alpha[y*w+w-1]==0 for y in range(h)))

    def test_recorded_content_and_frame_opening_bounds_are_valid(self):
        exports=json.loads((ART/'runtime_exports.json').read_text())
        for name,item in exports.items():
            with self.subTest(asset=name):
                box=item['content']
                self.assertGreater(box['w'],0)
                self.assertGreater(box['h'],0)
                self.assertGreaterEqual(box['x'],0)
                self.assertGreaterEqual(box['y'],0)
                self.assertLessEqual(box['x']+box['w'],1)
                self.assertLessEqual(box['y']+box['h'],1)
                path=RUNTIME/(Path(item['path']).name+'.tga')
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),item['sha256'])
        frame=exports['metalFrame'];outer=frame['content'];inside=frame['opening']
        self.assertGreater(inside['x'],outer['x'])
        self.assertGreater(inside['y'],outer['y'])
        self.assertLess(inside['x']+inside['w'],outer['x']+outer['w'])
        self.assertLess(inside['y']+inside['h'],outer['y']+outer['h'])
        diamond=exports['diamond'];b=diamond['content']
        self.assertLess(diamond['width']*b['w']/(diamond['height']*b['h']),.9)
        max_label=exports['maxLabel'];b=max_label['content']
        self.assertGreater(max_label['width']*b['w']/(max_label['height']*b['h']),2.4)

if __name__=='__main__':unittest.main()

