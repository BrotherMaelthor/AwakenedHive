data:extend({
    {
        type = "bool-setting",
        name = "AwakenedHive-Notifications",
        setting_type = "runtime-per-user",
        default_value = false,
        order = "d"
    },
    {
        type = "bool-setting",
        name = "AwakenedHive-ReduceEvolution",
        setting_type = "runtime-global",
        default_value = true,
        order = "e"
    },
    {
        type = "double-setting",
        name = "AwakenedHive-ReduceEvolutionAmount",
        setting_type = "runtime-global",
        default_value = 0.05,
        minimum_value = 0.01,
        maximum_value = 0.1,
        order = "f"
    },
    {
        type = "int-setting",
        name = "AwakenedHive-CycleLength",
        setting_type = "runtime-global",
        default_value = 15,
        minimum_value = 10,
        maximum_value = 30,
        order = "c"
    },
    {
        type = "int-setting",
        name = "AwakenedHive-GracePeriod",
        setting_type = "runtime-global",
        default_value = 60,
        minimum_value = 30,
        maximum_value = 120,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "AwakenedHive-BiterCleanup",
        setting_type = "runtime-global",
        default_value = true,
        order = "g"
    },
    {
        type = "string-setting",
        name = "AwakenedHive-Difficulty",
        setting_type = "runtime-global",
        default_value = "Normal",
        allowed_values = {'Easy', 'Normal', 'Hard', 'Extreme'},
        order = "a"
    },
    {
        type = "bool-setting",
        name = "AwakenedHive-Migrations",
        setting_type = "runtime-global",
        default_value = true,
        order = "h"
    }
})