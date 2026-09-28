"""Build pixel-identical WebP runtime assets while retaining source PNG files."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def main():
    before = after = 0
    for source in sorted((ROOT / 'assets/images').glob('*.png')):
        target = source.with_suffix('.webp')
        with Image.open(source) as image:
            original = image.convert('RGBA')
            original.save(target, 'WEBP', lossless=True, exact=True, method=6)
            with Image.open(target) as encoded:
                assert original.size == encoded.size
                assert original.tobytes() == encoded.convert('RGBA').tobytes(), source.name
        before += source.stat().st_size
        after += target.stat().st_size
    print(f'PNG source bytes: {before}; bundled WebP bytes: {after}; reduction: {100*(1-after/before):.1f}%')

if __name__ == '__main__':
    main()
