hl.workspace_rule({
    workspace = "special:screenshot",
    on_created_empty = "foot",
})

hl.config({
    plugin = {
        ["virtual_desktops"] = {
            names = "1:1, 2:2, 3:3, 4:4, 5:5",
            cycleworkspaces = 0,
            rememberlayout = "size",
            notifyinit = 1,
            verbose_logging = 0
        },
    }
})