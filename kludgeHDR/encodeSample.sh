set -x

ls -lt *HALD*tiff


crf=15

ffmpeg -y -t 2.0 -i $EDRDATA/UHD/prores/BourneUltimatum_NBC_Trim_HD_8Ch_PJ_Mezz.mov \
   -i InverseTC_HALD_Gamma.tiff \
   -sws_flags lanczos+accurate_rnd \
   -filter_complex "[0][1] haldclut, scale=3840:-1,unsharp=3:3:1.25:3:3:0.0" \
   -pix_fmt yuv420p10le -an \
   -r 24.0 -f rawvideo -vcodec rawvideo - | x265 \
        --input - \
        --input-depth 10 --input-res 3840x2160 --fps 24.0 \
        --profile main10 --level-idc 51 --no-high-tier --tune grain \
        --crf $crf   \
        -p veryfast  --bframes 12 -I 72 --psnr --sar 1 --range limited \
        --colorprim bt709 --transfer bt709 --colormatrix bt709 --chromaloc 1 \
        --repeat-headers  \
        -o x265-output-gamma-$crf.bin 

ffmpeg -y -t 2.0 -i $EDRDATA/UHD/prores/BourneUltimatum_NBC_Trim_HD_8Ch_PJ_Mezz.mov \
   -i InverseTC_HALD_PQ.tiff \
   -sws_flags lanczos+accurate_rnd \
   -filter_complex "[0][1] haldclut, scale=3840:-1,unsharp=3:3:1.25:3:3:0.0" \
   -pix_fmt yuv420p10le -an \
   -r 24.0 -f rawvideo -vcodec rawvideo - | x265 \
        --input - \
        --input-depth 10 --input-res 3840x2160 --fps 24.0 \
        --profile main10 --level-idc 51 --no-high-tier --tune grain \
        --crf $crf   \
        -p veryfast  --bframes 12 -I 72 --psnr --sar 1 --range limited \
        --colorprim bt2020 --transfer smpte-st-2084 --colormatrix bt2020nc --chromaloc 2 \
        --repeat-headers  \
        -o x265-output-PQ-$crf.bin 
  
  
mpv --loop 5  x265-output-gamma-$crf.bin 
mpv --loop 5  x265-output-PQ-$crf.bin 

  
exit
   
