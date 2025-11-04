#!/usr/bin/env python3
import sys
import subprocess
import os

# Validation flags that should run locally
VALIDATION_FLAGS = [
    '-version', '-f', '-formats', '-codecs', '-decoders', 
    '-encoders', '-bsfs', '-protocols', '-filters', 
    '-pix_fmts', '-layouts', '-sample_fmts', '-buildconf'
]

def main():
    args = sys.argv[1:]
    
    # If no args or validation flag, run local ffmpeg
    if not args or any(flag in args for flag in VALIDATION_FLAGS):
        ffmpeg_path = '/usr/lib/jellyfin-ffmpeg/ffmpeg'
        try:
            result = subprocess.run([ffmpeg_path] + args, check=False)
            sys.exit(result.returncode)
        except Exception as e:
            print(f"Error running local ffmpeg: {e}", file=sys.stderr)
            sys.exit(1)
    
    # For all other calls, use original rffmpeg
    rffmpeg_path = '/usr/local/bin/rffmpeg-original'
    try:
        result = subprocess.run([rffmpeg_path] + args, check=False)
        sys.exit(result.returncode)
    except Exception as e:
        print(f"Error running rffmpeg: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
