#!/bin/bash

shards="{ \
    rs_or0:{ minKey:-2147483648, p:'rosaluxemburg0'},        \
    rs_or1:{ minKey:-715827883, p:'rosaluxemburg2'},         \
    rs_or2:{ minKey:715827882, p:'rosaluxemburg4'},          \
    rs_or3:{ minKey:2147483648, p:'rosaluxemburg8'},         \
    rs_or4:{ minKey:3579139413, p:'rosaluxemburg10'},        \
    rs_or5:{ minKey:5010795178, p:'rosaluxemburg12'},        \
    rs_or6:{ minKey:6442450944, p:'rosaluxemburg14'},        \
    rs_or7:{ minKey:7874106709, p:'rosaluxemburg16'},        \
    rs_or8:{ minKey:9305762474, p:'rosaluxemburg18'},        \
    rs_or9:{ minKey:10737418240, p:'rosaluxemburg20'},       \
    rs_or10:{ minKey:12169074005, p:'rosaluxemburg22'},      \
    rs_or11:{ minKey:13600729770, p:'rosaluxemburg24'},      \
    rs_or12:{ minKey:15032385536, p:'rosaluxemburg26'},      \
    rs_or13:{ minKey:16464041301, p:'rosaluxemburg28'},      \
    rs_or14:{ minKey:17895697066, p:'rosaluxemburg30'}       \
};"

stats="{
    ""sharded"":true,                                            \
    ""ns"":""or_10622.master.chunks"",                             \
    ""count"":65294877,                                          \
    ""numExtents"":8475,                                         \
    ""size"":NumberLong(""17453411478172""),                       \
    ""storageSize"":NumberLong(""17996354581776""),                \
    ""totalIndexSize"":11856974192,                              \
    ""indexSizes"":{                                             \
        ""_id_"":2438263072,                                     \
        ""files_id_1_n_1"":9418711120                            \
    },                                                         \
    ""avgObjSize"":267301.39147320855,                           \
    ""nindexes"":2,                                              \
    ""nchunks"":138606,                                          \
    ""shards"":{                                                 \
        ""rs_or0"":{                                             \
            ""ns"":""or_10622.master.chunks"",                     \
            ""count"":18702100,                                  \
            ""size"":NumberLong(""5080919841472""),                \
            ""avgObjSize"":271676.4342759369,                    \
            ""storageSize"":NumberLong(""5316221117840""),         \
            ""numExtents"":2507,                                 \
            ""nindexes"":2,                                      \
            ""lastExtentSize"":2146426864,                       \
            ""paddingFactor"":1.000999999993229,                 \
            ""systemFlags"":0,                                   \
            ""userFlags"":0,                                     \
            ""totalIndexSize"":3333764000,                       \
            ""indexSizes"":{                                     \
                ""_id_"":677553296,                              \
                ""files_id_1_n_1"":2656210704                    \
            },                                                 \
            ""ok"":1                                             \
        },                                                     \
        ""rs_or1"":{                                             \
            ""ns"":""or_10622.master.chunks"",                     \
            ""count"":25329709,                                  \
            ""size"":NumberLong(""6622956374520""),                \
            ""avgObjSize"":261469.89586497025,                   \
            ""storageSize"":NumberLong(""6670616469024""),         \
            ""numExtents"":3138,                                 \
            ""nindexes"":2,                                      \
            ""lastExtentSize"":2146426864,                       \
            ""paddingFactor"":1,                                 \
            ""systemFlags"":0,                                   \
            ""userFlags"":0,                                     \
            ""totalIndexSize"":4650140880,                       \
            ""indexSizes"":{                                     \
                ""_id_"":972191808,                              \
                ""files_id_1_n_1"":3677949072                    \
            },                                                 \
            ""ok"":1                                             \
        },                                                     \
        ""rs_or2"":{                                             \
            ""ns"":""or_10622.master.chunks"",                     \
            ""count"":21263068,                                  \
            ""size"":NumberLong(""5749535262180""),                \
            ""avgObjSize"":270400.07877414493,                   \
            ""storageSize"":NumberLong(""6009516994912""),         \
            ""numExtents"":2830,                                 \
            ""nindexes"":2,                                      \
            ""lastExtentSize"":2146426864,                       \
            ""paddingFactor"":1.0009999999934875,                \
            ""systemFlags"":0,                                   \
            ""userFlags"":0,                                     \
            ""totalIndexSize"":3873069312,                       \
            ""indexSizes"":{                                     \
                ""_id_"":788517968,                              \
                ""files_id_1_n_1"":3084551344                    \
            },                                                 \
            ""ok"":1                                             \
        },                                                     \
        ""rs_or9"":{                                             \
            ""ns"":""or_10622.master.chunks"",                     \
            ""count"":21263068,                                  \
            ""size"":NumberLong(""5749535262180""),                \
            ""avgObjSize"":270400.07877414493,                   \
            ""storageSize"":NumberLong(""6009516994912""),         \
            ""numExtents"":2830,                                 \
            ""nindexes"":2,                                      \
            ""lastExtentSize"":2146426864,                       \
            ""paddingFactor"":1.0009999999934875,                \
            ""systemFlags"":0,                                   \
            ""userFlags"":0,                                     \
            ""totalIndexSize"":3873069312,                       \
            ""indexSizes"":{                                     \
                ""_id_"":788517968,                              \
                ""files_id_1_n_1"":3084551344                    \
            },                                                 \
            ""ok"":1                                             \
        }                                                      \
                                                               \
    },                                                         \
    ""ok"":1                                                     \
};"