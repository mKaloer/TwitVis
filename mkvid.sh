#!/bin/bash
ffmpeg -r 3 -i world_%d.png -vcodec mpeg4 output.avi
exit 0