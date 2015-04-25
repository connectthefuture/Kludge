#set -x
echo 'using the aces 0.7.1 utility ctl files'

# create exr with value
#  ctlrender -force -ctl $EDRHOME/ACES/CTL/EXRvalue.ctl -param1 value 26.0 EXRv11Stills/OBL/001466.exr -format exr16 v10_225.exr

#
# Create LUTS
#

CUBE=64
FUDGE=1.0
MOVIE=/Users/patrickcusack/ACES/Files/MP_HD_ProRes_2398p_CLEAN_SUB.mov

# Create LUT using PQ based shaper
#ociolutimage --generate --cubesize $CUBE --maxwidth 512 --output lutimagePQ.tiff
#ctlrender -force \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 100.0 -param1 DISPGAMMA 2.4 \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $RANGE -param1 DISPGAMMA 2.4 \
    #lutimagePQ.tiff -format tiff16 Plus2StretchHALD.tiff
    
ociolutimage --generate --cubesize $CUBE --maxwidth 512 --output lutimagePQ.tiff
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_smpte_inv_MAX.ctl \
      -param1 MAX 100.0 -param1 DISPGAMMA 2.4 -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/odt_PQ10k2020.ctl \
    lutimagePQ.tiff -format tiff16 InverseTC_HALD_PQ.tiff    

#     -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX_CLIP.ctl -param1 MAX 400.0 -param1 DISPGAMMA 2.2 \

ociolutimage --generate --cubesize $CUBE --maxwidth 512 --output lutimagePQ.tiff
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_smpte_inv_MAX.ctl \
      -param1 MAX 100.0 -param1 DISPGAMMA 2.4 -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl \
         -param1 MAX 600.0 -param1 FUDGE 1.1 -param1 DISPGAMMA 2.4 \
    lutimagePQ.tiff -format tiff16 InverseTC_HALD_Gamma.tiff    

#ociolutimage --extract --cubesize $CUBE --maxwidth 512 -input InverseTC_HALD.tiff --output InverseTC_HALD.spi3d
#ociobakelut --lut InverseTC_HALD.spi3d --format iridas_itx --cubesize $CUBE  InverseTC_HALD.cube


echo 'generating files'

crf=15

ffmpeg -y -t 8.0 -i $MOVIE \
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

ffmpeg -y -t 8.0 -i $MOVIE \
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
  
  
exit
   
