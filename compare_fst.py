from vcdvcd import VCDVCD


def compare_data(d1, d2):
    for i in range(min(len(d1), len(d2))):
        if d1[i] != d2[i]:
            t1, _ = d1[i]
            t2, _ = d2[i]
            return min(t1, t2)
    if len(d1) < len(d2):
        return d2[-1][0]
    elif len(d1) > len(d2):
        return d1[-1][0]
    return None

def get_vcd(path):
    vcd = VCDVCD(path)
    
    imp_signals = ["TOP.top_verilator.u_ibex_demo_system.u_top.data_rdata_i",
                   "TOP.top_verilator.u_ibex_demo_system.u_bus.",
                   "TOP.top_verilator.u_ibex_demo_system.u_gpio.",
                   "TOP.top_verilator.u_ibex_demo_system.u_ram.",]
    
    sigs = []
    
    for signal in vcd.signals:
        for s2 in imp_signals:
            if signal.startswith(s2):
                sigs.append(signal)
    
    vcd = VCDVCD(path, signals=sigs)

    ret = {}
    for x in vcd.data.keys():
        d = vcd.data[x]
        for refer in d.references:
            ret[refer] = d.tv
    return ret

v1 = get_vcd("sim.vcd")
v2 = get_vcd("sim_og.vcd")

mdt = None
ms = []

for s in v1.keys():
    dt = compare_data(v1[s], v2[s])
    print(s, dt)
    if dt != None and dt != 0:
        if mdt == None:
            mdt = dt
            ms = [s]
        else:
            if dt == mdt:
                ms.append(s)
            elif dt < mdt:
                ms = [s]
            mdt = min(mdt, dt)

print(ms, mdt)
