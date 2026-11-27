// Log Grapple: every log and pulpwood loader on the map loads at least as fast as the game's own fastest
// (Graham County Pulpwood, 3,000 tons/day). Never lowers a rate. Found at map load, not hard-coded, so it
// keeps working after map updates and on other maps.
//
// Why: 0.6.0 loads spotted cars one after another from one shared per-tick budget (IndustryLoader.Service:
// num -= num3), so a 1.2M lb/day log loader fills one ~25 T car per game hour and a 300k pulpwood spur is
// far slower. Production and storage are untouched: a fast grapple can still run the pile dry and then wait.
// Milestone-gated loaders (Connelly L2/L3 and friends) still unlock normally; only their rate changes.
//
// Crossover (0.4.1): at a camp, a log loader and a pulpwood loader whose tracks are in the SAME track group
// (built by the same milestone) also load on each other's tracks: Connelly L1+P1 (base), L2+P2 (connelly-l2),
// L3+P3/P4 (connelly-l3), Walker L1+LP1 (walker). Each loader keeps its own pile (sharedStorage false), so this
// adds tracks, not output; the car's destination ("Connelly Creek P1" etc.) still picks the load and the pile.
// 0.4.0 gave every camp loader ALL camp spans, which put L1/P1 on spans whose track isn't built yet, and a loader
// with a span on missing track reports "not connected to track" and loads nothing (10-28). Pairing by
// track group makes that impossible: tracks in one group exist together. Found by rule, not by name.
//
// Scott Tie Plant (0.5.2): its log unloader (sylva.sylva-ties.logs, 3.6M lb/day) unloads as fast as the Whittier Saw
// Mill's (whittier.whittier-sawmill.logs, 72M on the 0.6.3 map). The sawmill's rate is read from the map at load, so a
// game retune of it carries over; if that component is missing, the constant below (the 0.6.3 value) is used. Never
// lowers a rate; storage and consumption untouched. modifyMap edits the raw map JSON, so it reaches existing saves;
// A mod that scales unload rates after this runs reads the raised carUnloadRate from the live unloader.
//
// Production variants (0.5.4): MULT below multiplies the productionRate, carLoadRate and maxStorage of every log and pulpwood LOADER (isTimber:
// an IndustryLoader of rr/logs or rr/pulpwood with a production rate above zero), after the raise above. Found by the same rule,
// not by id: on the 0.6.3 base map that is Connelly Creek, Walker Upper and Lower, and the three pulpwood sidings. The Scott Tie
// Plant (it unloads logs, and its loader makes ties) and the Whittier Saw Mill are not log or pulpwood loaders, so the rule leaves
// them alone. At 1.0 nothing is written, so the map is exactly 0.5.3's. tools/package.sh makes the 2x to 5x zips by rewriting only
// the MULT line. Loading speed (carLoadRate, after the floor raise) is scaled by MULT too, so a camp can ship what it makes.
//
// Gondolas (0.5.0): logs may ride in gondolas as well as log flats, for captive log service in your own gons
// (10-29). No log loader or unloader on the map sets its own car filter (Connelly L1-L3, Bryson log camp, Whittier Saw
// Mill R1, Sylva Ties), so they all inherit the Logs load's "FL"; adding "GB*" there opens every one of them to any
// gondola type. Map-wide: an unloader that orders logs (Sylva Ties) may now also be sent logs in gondolas. Appended,
// never replaced, so another mod's filter change survives. Info.json requires rr/loads so this runs after the core
// loads exist (Data.rl only sees packs ordered before it).
//
// Logs draw as logs (0.5.5): a gondola's load model is picked by the load id and the car type (CarLoadModelCoordinator, then
// LoadModelVolumeController.TryGetLoadModelDefinition); no model listed rr/logs, so logs in a gondola drew the generic crate. This adds
// one StaticLoadModel for rr/logs on GB* cars (12 logs of the game's own rr/log-large-01 mesh, a 5-4-3 pile, bottom row first), sized
// to fit inside the smallest gondola volume so nothing is scaled. The pick among several candidates has no priority, so the filter is
// GB* and no other model lists rr/logs. The game's pulpwood model already admits GB but its minimum height (1.8 m) only fits the
// 40ft wood gondola; the minimum goes to 1.2 m, from the exact vanilla value only, so the other four gondolas draw pulpwood too.
// Info.json requires the packs that own the base model (loads-models01), the log mesh (fl-skeleton01) and the pulpwood model (fb-flatcar04).
//
// Walker camp spans (0.5.6): Walker Upper's two log tracks (l2, l3) and Walker Lower's two (l1-0, l1-1) used to stop 50 to 80 m short
// of their switches. Each span's switch end moves out to just past the switch's fouling distance (the game's own number,
// GraphFoulingExtension.CalculateFoulingDistance: 41 m at Walker Upper's switch, 29 m at Walker Lower's; 0.1 m past it here), so a car on
// the loader never sits on the switch or the track beside it. The stub end stays where it was. Only the four lists below change; they
// are replaced whole, and only when all four are exactly the game's own (a changed map or another mod's edit: left alone). The pulpwood
// spans and every other span are untouched. tools/check_walker.py proves the new ends against the track graph.

import log

let target = 6000000.0
let MULT = 1.0   // production variant, 1.0 (the main file) to 5.0
let sawmillRate = 72000000.0   // fallback only: Whittier Saw Mill R1's carUnloadRate on the 0.6.3 map

let walkerIds = ["l1-0", "l1-1", "l2", "l3"]
let walkerFrom = [["St68|b|0.432", "St68|a|48.821"], ["Smn9|b|0.146", "Sd8f|a|50.372"], ["S4yp|b|0.293", "S4yp|a|80.815"], ["Ss3x|a|79.085", "S4tr|b|0.575"]]
let walkerTo = [["St68|b|0.432", "St68|a|29.1"], ["Smn9|b|0.146", "Sd8f|a|29.1"], ["S4yp|b|0.293", "S4yp|a|41.1"], ["Ss3x|a|41.1", "S4tr|b|0.575"]]

func sameRefs(a, b) {
    if a.count != b.count { return false }
    var i = 0
    while i < b.count {
        if a[i] != b[i] { return false }
        i = i + 1
    }
    return true
}

func isTimber(c) {
    if !c.has("kind") || !c.has("loadId") { return false }
    if c["kind"] != "IndustryLoader" { return false }
    return c["loadId"] == "rr/logs" || c["loadId"] == "rr/pulpwood"
}

// The track groups a loader's spans sit on ("" = base track). Span refs are "segmentKey|end|distance".
func groupsOf(segs, spanDefs, spans) {
    var out = []
    for s in spans {
        if !spanDefs.has(s) { continue }
        for ref in spanDefs[s] {
            var parts = ref.split("|")
            var sid = parts[0]
            var g = ""
            if segs.has(sid) && segs[sid].has("groupId") { g = segs[sid]["groupId"] }
            if !out.contains(g) { out.add(g) }
        }
    }
    return out
}

func shareGroup(a, b) {
    for g in a {
        if b.contains(g) { return true }
    }
    return false
}

// The Whittier Saw Mill's log unloader rate from the map, or the constant if it isn't there.
func sawmillUnloadRate(areas) {
    if !areas.has("whittier") || !areas["whittier"].has("industries") { return sawmillRate }
    var inds = areas["whittier"]["industries"]
    if !inds.has("whittier-sawmill") || !inds["whittier-sawmill"].has("components") { return sawmillRate }
    var comps = inds["whittier-sawmill"]["components"]
    if !comps.has("logs") { return sawmillRate }
    var c = comps["logs"]
    if !c.has("carUnloadRate") || !c.has("kind") || c["kind"] != "IndustryUnloader" { return sawmillRate }
    return c["carUnloadRate"]
}

let logModel = "ashenmare/loadmodel-logs-gondola"
let pulpModel = "rr/loadmodel-pulpwood-40ft"
let pulpMinFrom = [2.0, 1.8, 8.0]   // the game's value
let pulpMinTo = [2.0, 1.2, 8.0]

func sameSize(a, b) {
    if a == null { return false }
    if a.count != b.count { return false }
    var i = 0
    while i < b.count {
        if a[i] != b[i] { return false }
        i = i + 1
    }
    return true
}

// 12 logs, rows of 5, 4 and 3, bottom row first so each log rests on the ones before it. 0.40 m across, 9.4 m long
// (the mesh is 0.236 x 0.226 x 1.271 m with its long axis on z), centered on the volume, so no rotation.
func logPile() {
    var xs = [[-0.8, -0.4, 0.0, 0.4, 0.8], [-0.6, -0.2, 0.2, 0.6], [-0.4, 0.0, 0.4]]
    var ys = [0.2, 0.5464, 0.8928]
    var out = []
    var r = 0
    while r < xs.count {
        for x in xs[r] {
            out.add({ "position": [x, ys[r], 0.0], "rotation": [0.0, 0.0, 0.0, 1.0], "scale": [1.695, 1.695, 7.396] })
        }
        r = r + 1
    }
    return out
}

func modifyDefinitions(context) {
    context.modify("rr/logs", (obj) => {
        var d = obj["definition"]
        var f = d.has("carTypeFilter") ? d["carTypeFilter"] : ""
        if f.split(",").contains("GB*") { return }
        var now = (f == "") ? "FL,GB*" : f + ",GB*"
        obj["definition"]["carTypeFilter"] = now
    })
    // The logs model: a copy of the game's ties model with its models, instances, load, filter and size replaced.
    context.modifyAs("rr/loadmodel-ties", logModel, (obj) => {
        obj["metadata"]["name"] = "loadmodel-logs-gondola"
        obj["metadata"]["description"] = "Logs in gondolas."
        var d = obj["definition"]
        d["models"] = ["rr/log-large-01"]
        d["instances"] = logPile()
        d["loadIdentifiers"] = ["rr/logs"]
        d["carTypeFilter"] = "GB*"
        d["size"] = [2.3, 1.2, 9.5]
        d["minimumSize"] = [2.3, 1.2, 9.5]
        d["maximumSize"] = [100.0, 100.0, 100.0]
    })
    // Pulpwood: only the minimum height, and only from the game's exact value.
    var pulp = "set"
    context.modify(pulpModel, (obj) => {
        var d = obj["definition"]
        var m = d.has("minimumSize") ? d["minimumSize"] : null
        if sameSize(m, pulpMinTo) {
            pulp = "already set"
            return
        }
        if !sameSize(m, pulpMinFrom) {
            pulp = "left alone"
            log.warning("[log-grapple] \(pulpModel) minimum size is \(m), not the expected \(pulpMinFrom); left alone")
            return
        }
        d["minimumSize"] = pulpMinTo
    })
    log.info("[log-grapple] logs draw as logs in gondolas (\(logModel)); pulpwood minimum height \(pulp)")
}

func modifyMap(map) {
    map.modify((data) => {
        if !data.has("ops") || !data["ops"].has("areas") { return }
        var segs = (data.has("graph") && data["graph"].has("segments")) ? data["graph"]["segments"] : {}
        var raised = []
        var crossed = []
        var tied = 0
        var scaled = []
        var areas = data["ops"]["areas"]
        var tieRate = sawmillUnloadRate(areas)
        if areas.has("sylva") && areas["sylva"].has("industries") && areas["sylva"]["industries"].has("sylva-ties")
            && areas["sylva"]["industries"]["sylva-ties"].has("components")
            && areas["sylva"]["industries"]["sylva-ties"]["components"].has("logs") {
            var tie = areas["sylva"]["industries"]["sylva-ties"]["components"]["logs"]
            var tieNow = tie.has("carUnloadRate") ? tie["carUnloadRate"] : 1.0
            if tie.has("kind") && tie["kind"] == "IndustryUnloader" && tie.has("loadId") && tie["loadId"] == "rr/logs" && tieNow < tieRate {
                data["ops"]["areas"]["sylva"]["industries"]["sylva-ties"]["components"]["logs"]["carUnloadRate"] = tieRate
                tied = 1
            }
        }
        // Scott Tie Plant (0.5.3): logs and creosote unload on t1 and t2, ties load and sell on t1 and t2. Each component keeps its own
        // track first (the game tries a component's spans in order). Stands down unless t1 and t2 exist, sit in one track group, and each
        // component is the expected kind and load on exactly its one track. Uses the map's own span ids, so no span is added or changed.
        var both = 0
        if areas.has("sylva") && areas["sylva"].has("industries") && areas["sylva"]["industries"].has("sylva-ties") {
            var plant = areas["sylva"]["industries"]["sylva-ties"]
            if plant.has("trackSpans") && plant.has("components") && plant["trackSpans"].has("t1") && plant["trackSpans"].has("t2")
                && shareGroup(groupsOf(segs, plant["trackSpans"], ["t1"]), groupsOf(segs, plant["trackSpans"], ["t2"])) {
                var pcomps = plant["components"]
                var pids = ["logs", "creosote", "ties", "ties-seller"]
                var pkinds = ["IndustryUnloader", "IndustryUnloader", "IndustryLoader", "IndustrySeller"]
                var ploads = ["rr/logs", "rr/creosote", "rr/ties", "rr/ties"]
                var pown = ["t1", "t1", "t2", "t2"]
                var pother = ["t2", "t2", "t1", "t1"]
                var pi = 0
                for pid in pids {
                    var k = pi
                    pi = pi + 1
                    if !pcomps.has(pid) { continue }
                    var pc = pcomps[pid]
                    if !pc.has("kind") || pc["kind"] != pkinds[k] || !pc.has("loadId") || pc["loadId"] != ploads[k] { continue }
                    if !pc.has("trackSpans") || pc["trackSpans"].count != 1 || pc["trackSpans"][0] != pown[k] { continue }
                    data["ops"]["areas"]["sylva"]["industries"]["sylva-ties"]["components"][pid]["trackSpans"] = [pown[k], pother[k]]
                    both = both + 1
                }
            }
        }
        // Walker camp spans (0.5.6): all four exactly as the game ships them, or none is touched.
        var longer = 0
        if areas.has("bryson-above") && areas["bryson-above"].has("industries") && areas["bryson-above"]["industries"].has("logcamp1")
            && areas["bryson-above"]["industries"]["logcamp1"].has("trackSpans") {
            var wspans = areas["bryson-above"]["industries"]["logcamp1"]["trackSpans"]
            var vanilla = true
            var wi = 0
            for wid in walkerIds {
                if !wspans.has(wid) || !sameRefs(wspans[wid], walkerFrom[wi]) { vanilla = false }
                wi = wi + 1
            }
            if vanilla {
                wi = 0
                for wid in walkerIds {
                    data["ops"]["areas"]["bryson-above"]["industries"]["logcamp1"]["trackSpans"][wid] = walkerTo[wi]
                    wi = wi + 1
                    longer = longer + 1
                }
            }
        }
        for aid in areas {
            if !areas[aid].has("industries") { continue }
            var industries = areas[aid]["industries"]
            for iid in industries {
                if !industries[iid].has("components") { continue }
                var comps = industries[iid]["components"]
                for cid in comps {
                    var c = comps[cid]
                    if !isTimber(c) { continue }
                    var rate = c.has("carLoadRate") ? c["carLoadRate"] : 1.0
                    if rate < target {
                        // write through the full path (the docs' form) so it lands in the map either way
                        data["ops"]["areas"][aid]["industries"][iid]["components"][cid]["carLoadRate"] = target
                        raised.add(iid + "." + cid)
                    }
                    if MULT > 1.0 && c.has("productionRate") && c["productionRate"] > 0.0 {
                        data["ops"]["areas"][aid]["industries"][iid]["components"][cid]["productionRate"] = c["productionRate"] * MULT
                        data["ops"]["areas"][aid]["industries"][iid]["components"][cid]["carLoadRate"] = (rate < target ? target : rate) * MULT
                        if c.has("maxStorage") {
                            data["ops"]["areas"][aid]["industries"][iid]["components"][cid]["maxStorage"] = c["maxStorage"] * MULT
                        }
                        scaled.add(iid + "." + cid)
                    }
                }
                if !industries[iid].has("trackSpans") { continue }
                var spanDefs = industries[iid]["trackSpans"]
                // Snapshot first, so the order we visit loaders in can't change what any of them gets.
                var ids = []
                var own = {}
                var groups = {}
                for cid in comps {
                    var c = comps[cid]
                    if !isTimber(c) || !c.has("trackSpans") { continue }
                    var copy = []
                    for s in c["trackSpans"] { copy.add(s) }
                    ids.add(cid)
                    own.add(cid, copy)
                    groups.add(cid, groupsOf(segs, spanDefs, copy))
                }
                for xid in ids {
                    var mine = []
                    for s in own[xid] { mine.add(s) }   // its own tracks first
                    for yid in ids {
                        if comps[yid]["loadId"] == comps[xid]["loadId"] { continue }   // only the other load's tracks
                        if !shareGroup(groups[xid], groups[yid]) { continue }
                        for extra in own[yid] {
                            if !mine.contains(extra) { mine.add(extra) }
                        }
                    }
                    if mine.count > own[xid].count {
                        data["ops"]["areas"][aid]["industries"][iid]["components"][xid]["trackSpans"] = mine
                        crossed.add(iid + "." + xid)
                    }
                }
            }
        }
        // The one line this script writes at startup (HOUSE 1.9): the counts and, for a bug report, the loader ids (industry.component, the
        // game's own component ids), since a Data.rl can't write to the debug log.
        var made = ""
        if MULT > 1.0 { made = "; production and loading x\(MULT) on \(scaled.count) log/pulpwood loaders (\(scaled.join(", ")))" }
        log.info("[log-grapple] raised \(raised.count) log/pulpwood loaders to \(target) lb/day (\(raised.join(", "))); \(crossed.count) camp loaders also load on their same-group partner's tracks (\(crossed.join(", "))); \(tied) tie plant unloader raised; \(both) tie plant components on both tracks; \(longer) Walker camp spans lengthened\(made)")
    })
}
