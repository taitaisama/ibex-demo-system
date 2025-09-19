import sys
import vitis


def make_platform(workspace_path, hw_path, C_path):

    client = vitis.create_client()
    client.set_workspace(path=workspace_path)

    platform = client.create_platform_component(name = "platform",hw_design = hw_path,os = "standalone",cpu = "psv_cortexa72_0")
    status = platform.build()

    comp = client.create_app_component(name="hello_world",platform = workspace_path+"/platform/export/platform/platform.xpfm",domain = "standalone_psv_cortexa72_0",template = "hello_world")

    comp = client.get_component(name="hello_world")
    comp.build()
    

make_platform(sys.argv[1], sys.argv[2], sys.argv[3])
