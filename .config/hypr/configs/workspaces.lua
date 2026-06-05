hl.config({
    plugin = {
        ["virtual-desktops"] = {
            names = "1:first, 2:second, 3:third, 4:fourth, 5:fifth",
            cycleworkspaces = 0,
            rememberlayout = "size",
            notifyinit = 1,
            verbose_logging = 0,
        },
    },
})

hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})
