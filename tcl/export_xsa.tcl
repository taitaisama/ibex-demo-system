set dir_path [lindex $argv 0]

launch_runs synth_1 -quiet -jobs 16
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1
write_hw_platform -fixed -include_bit -force -file $dir_path/build/hardware/top_versal.xsa
