
proc gen_ibex_ip { base_path } {
    set_property source_mgmt_mode All [current_project]
    set_property  ip_repo_paths $base_path/ibex_intf/ip_repo [current_project]
    update_ip_catalog
    ipx::package_project -root_dir $base_path/build/ip_repo -vendor user.org -library user -taxonomy /UserIP -import_files
    set_property core_revision 2 [ipx::current_core]
    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::check_integrity [ipx::current_core]
    ipx::save_core [ipx::current_core]
}

set dir_path [lindex $argv 0]

gen_ibex_ip $dir_path
