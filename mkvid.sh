#!/bin/bash
ffmpeg -r ${2:-3} -i $1/world_%d.png -vcodec mpeg4 output.avi
exit 0