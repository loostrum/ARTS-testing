#!/bin/bash
#
# Test the MOM / MOMAD implementation of SNR in AMBER

fname=/data2/output/dm1500.0_nfrb50_20180430-0840.fil
hdrsize=455
nbatch=10  # 100
output=amber_test_momad
snrmin=8
#req_dedisp=(0 1 2 3)
req_dedisp=(1)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

if [ ! -f $fname ]; then
    echo "File does not exist: $fname"
    exit 1
fi

################
# General      #
################
general="-opencl_platform 0 -print -sync -subband_dedispersion -sigproc -stream -snr_momad -threshold $snrmin"

################
# Dedispersion #
# 0 to 406.4   #
# 1 to 1219.2  #
# 2 to 3251.2  #
# 3 to 15443.2 #
################
dedisp_0="-opencl_device 0 -device_name ARTS_step1 -subbands 32 -dms 32 -dm_first 0 -dm_step .1 -subbanding_dms 128 -subbanding_dm_first 0 -subbanding_dm_step 3.2"
dedisp_1="-opencl_device 1 -device_name ARTS_step2 -subbands 32 -dms 32 -dm_first 0 -dm_step .2 -subbanding_dms 128 -subbanding_dm_first 406.4 -subbanding_dm_step 6.4"
dedisp_2="-opencl_device 2 -device_name ARTS_step3 -subbands 32 -dms 32 -dm_first 0 -dm_step .5 -subbanding_dms 128 -subbanding_dm_first 1219.2 -subbanding_dm_step 16"
dedisp_3="-opencl_device 3 -device_name ARTS_step4 -subbands 32 -dms 32 -dm_first 0 -dm_step 3 -subbanding_dms 128 -subbanding_dm_first 3251.2 -subbanding_dm_step 96"
all_dedisp=("$dedisp_0" "$dedisp_1" "$dedisp_2" "$dedisp_3")

################
# Sigproc      #
################
sigproc="-header $hdrsize -data $fname -batches $nbatch -channel_bandwidth .1953125 -min_freq 1220.09765625 -channels 1536 -samples 25000 -sampling_time 4.096e-05"

################
# Config       #
################
c=$script_dir/confs
config="-padding_file $c/padding.conf -zapped_channels $c/zapped_channels.conf -integration_steps $c/integration_steps.conf -integration_file $c/integration.conf -dedispersion_stepone_file $c/dedispersion_stepone.conf -dedispersion_steptwo_file $c/dedispersion_steptwo.conf -max_file $c/max.conf -mom_stepone_file $c/mom_stepone.conf -mom_steptwo_file $c/mom_steptwo.conf -momad_file $c/momad.conf"


# run one instance for each requested dedisp
mkdir -p $script_dir/log $script_dir/output 3>/dev/null
for i in ${req_dedisp[@]}; do
    dedisp=${all_dedisp[$i]}
    amber $general $dedisp $sigproc $config -output $script_dir/output/${output}_step${i} 2>&1 | tee $script_dir/log/AMBER_step${i}.log &
done

wait

exit 0
