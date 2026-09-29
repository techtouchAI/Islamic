"""Sign the immutable GitHub APK URL and digest with the CI-only Ed25519 key."""
import argparse
import base64
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', required=True, type=int)
    parser.add_argument('--min-build', required=True, type=int)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--apk', required=True, type=Path)
    parser.add_argument('--key', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    if args.build <= 0 or args.min_build < 0 or args.min_build > args.build:
        raise ValueError('Invalid build numbers')
    url = f'https://github.com/techtouchAI/Islamic/releases/download/{args.tag}/{args.apk.name}'
    checksum = hashlib.sha256(args.apk.read_bytes()).hexdigest()
    payload = f'{args.version}\n{args.build}\n{args.min_build}\n{url}\n{checksum}'.encode()
    with tempfile.NamedTemporaryFile() as payload_file:
        payload_file.write(payload)
        payload_file.flush()
        signature = subprocess.run(
            ['openssl', 'pkeyutl', '-sign', '-rawin', '-inkey', str(args.key),
             '-in', payload_file.name],
            stdout=subprocess.PIPE, check=True,
        ).stdout
    args.output.write_text(json.dumps({
        'version': args.version,
        'build_number': args.build,
        'min_supported_build': args.min_build,
        'apk_url': url,
        'sha256': checksum,
        'signature': base64.b64encode(signature).decode('ascii'),
    }, indent=2) + '\n')


if __name__ == '__main__':
    main()
