classdef TestX13Run < matlab.unittest.TestCase
%TESTX13RUN  End-to-end X13 run tests ported from test_x13run.jl.
    %   These tests require a working X13-ARIMA-SEATS executable. Update the
    %   X13ExecutablePath constant below before running the suite.

    properties (Constant, Access = private)
        X13ExecutablePath = "/apps/linux/xarima/x13as/x13as_ascii"
        % https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=2010000101
        mvsales = [14026,18340,20896,21421,15978,17416,19623,22482,21567,24160,27260,31793,33468,33468,36070,36341,31306,43740,44867,40531,33235,26938,25555,40688,37690,37710,43431,33001,27616,37720,41741,44097,43031,25386,32984,52640,60856,59577,57546,59295,37086,56657,61594,40301,44803,55003,59803,70817,74109,82114,93811,89343,67981,83062,74479,71366,63782,76648,101020,116907,114159,92670,83750,74539,55081,70836,58049,55629,50873,52966,66166,85656,102928,123352,106320,94224,66350,78771,83880,78592,63412,75031,96516,124814,140674,133302,118005,106789,73145,75755,82769,71750,63921,59204,76864,116961,121793,113534,100391,85919,69868,71881,53389,55917,63797,57509,70046,92435,143719,159987,146006,126378,111270,85961,93986,83251,85342,63791,85975,128272,169259,189177,169710,147728,120925,98092,97733,90823,93890,101295,98952,138462,164918,163236,135534,123716,109997,95692,76094,77947,83088,94358,95032,125078,158422,146776,136284,123589,93153,81790,101647,98179,111158,103828,114828,150070,179815,169327,173526,130971,114541,94969,113022,107519,87752,101630,122915,152950,172305,174514,173781,116751,105641,93835,119567,126420,114518,101581,110050,136687,155335,176826,159450,134574,110324,86651,115575,150105,114250,133180,118108,173329,186628,222959,182954,139128,106974,70550,149172,154452,145482,137125,143862,175270,229596,229994,212119,154817,110362,100826,187701,203618,176749,172961,177034,228289,255588,261534,236405,190015,139231,144514,197896,179470,154865,171132,178737,251435,288616,294183,284237,214519,186539,142779,228804,254410,243938,196285,206228,323969,268718,257376,267288,205565,210085,178182,232026,243176,235693,188347,187814,280274,268366,333304,309820,195671,190084,181575,229939,223692,209480,209047,213980,283693,274701,337345,295103,257824,224387,197146,305942,270435,246186,226767,254431,316694,339310,339274,319481,249978,197795,264272,309598,278919,226360,183331,188936,264384,288779,289895,305478,234446,188705,211277,283451,205479,168169,153062,205214,316591,365544,381388,359354,273128,219354,297968,374645,330785,276018,232850,271410,369016,383121,512031,451966,324903,292663,307104,453885,401762,312348,322342,366535,568805,554044,554222,550892,382970,381922,367073,523759,458179,339631,405002,423620,498786,581825,701937,592245,529880,495023,407736,523639,408324,348968,371997,480243,545762,655550,714015,741305,623215,557131,506181,765010,649542,651057,420554,503246,686400,795913,820201,832160,634717,568959,437967,844207,626712,583052,598258,609386,807531,788144,875594,854228,681548,684133,555836,847430,704168,539637,575773,660336,830586,931013,1042458,1027501,812087,761198,774534,925044,727857,581139,675053,796882,1097470,1053106,1213227,1161160,1070845,869164,830222,1145045,876048,693760,768414,885916,1083029,1116821,1009042,1005136,1003537,912937,846855,1134927,882178,729812,772176,856473,1214141,1312656,1207138,1194488,967396,851933,877823,903222,1066638,694311,583665,746980,941897,999456,1011831,1093600,679446,752619,786239,733560,765224,729454,580247,680991,1138305,1244840,1187227,1251451,941425,1002558,906721,1164248,1199996,898317,923557,1120598,1528335,1471449,1683172,1620562,1260598,1186586,1013207,1532192,1266907,1072597,1140754,1214675,1741819,2030177,2007142,2058585,1610115,1598249,1454694,1884221,1696384,1453304,1341418,1539214,1829544,2311485,2220368,2046566,1976171,1736781,1709660,1931456,1601001,1597886,1286498,1567720,2248091,2591424,2338435,2602299,1937215,1990052,1838712,2267914,2007771,1795621,1526332,1756302,2705521,2694627,2863769,2546215,2133750,2218823,2017577,2284684,2154222,1963505,1546441,1798941,2430460,3073601,3122309,2565379,1990790,2189513,2115091,2300071,2112901,1713881,1716818,1688292,2629595,2548948,2761967,2555167,2066940,2015164,1747583,2029481,1720832,1407964,1438359,1432005,1914665,2458908,2554881,2510073,2172463,1714919,1830044,1758944,1651890,1418475,1503355,1577017,2089908,2377625,2351046,2352791,2075113,1869378,1996506,1871867,1741878,1677971,1362140,1394538,2308600,2485723,2582940,2414027,2185670,1966377,1962682,2041452,2058835,1867375,1647772,1747093,2641147,2744338,2934499,2925984,2255666,2096987,2251448,2377165,2262384,2009312,1770967,1869733,2669870,2478218,3004407,2908311,2212189,2354999,2396467,2299947,2179178,2024520,1897218,2094659,2754785,2717501,3238183,3142366,2594296,2391307,2475602,2894859,2620513,2664488,2151641,2456273,3342741,3636853,3949541,3665600,3261313,2994791,3114374,3371864,3201748,3839485,2179285,2435964,3596739,3900578,4361440,4183374,3325536,3057786,3569508,3220716,3153269,3271582,2567669,2721576,4242978,4145962,4340828,4458515,3704818,3652492,4065544,3644129,3702038,4071365,2843715,3014977,4632012,4369507,4910387,4723138,3696472,4115554,4268641,3388700,3526918,3440493,2859254,2657565,4231569,4381553,4854163,4693081,3750259,3994642,3716896,3697632,3947242,4102396,3412178,3174004,4504327,4945277,5463686,5034008,4195497,4517781,4362089,4239363,3969183,4410106,2941847,3276166,4619716,4671934,5551388,4596710,4570411,4452716,4487201,3996557,3678577,3650085,2711635,3005344,4674152,4889605,5029987,4812540,4256526,4247689,4204154,4012022,3938961,3856608,2687357,3481340,4750643,5287013,5142342,5325761,4981923,4636671,4107993,3823755,4076656,4009693,2943630,3315853,5042821,5047812,5505594,5190119,4593190,5003098,4551778,4117566,4230872,4423928,3133627,3315696,5011240,5386679,5854394,5348247,4471995,4906210,4192666,3989014,3907470,4159628,3386322,3560284,4775620,5502356,5583623,4935721,4603855,4484657,4196301,3955760,3392779,3188261,2474417,2555416,4023591,4414203,4824893,4461372,4372313,4365353,4166515,4036810,3437215,3805490,2834682,3307185,4817510,4974619,4990170,5090394,4853046,4521798,4549860,4216887,4054432,4105026,2965868,3359312,5159286,5325409,5051223,5541638,4693564,4780998,4669021,4437146,4167963,3974503,3348298,3679112,5396923,5271661,5909814,5693440,4972339,5008633,4828816,4638168,4331407,3866028,3417225,3642985,5446411,5991964,6354237,5905953,5439723,5419180,5212522,5175550,4718693,4166792,3461575,3779018,5682849,6278892,6884962,6266851,6277118,6021329,6094943,5681354,5074899,5009469,3729812,4118142,5967542,6910768,7189418,6667610,6512342,6409757,6570649,6084201,5478891,5126074,4295419,4728596,6745037,7570371,7379863,7258509,6654406,6691685,6942118,6121957,6467708,5268834,4538110,5022160,7537573,7925441,8590484,8299645,7295374,7488038,7694331,6915797,6764403,5530452,5006244,5354688,8040083,8249951,9281703,8634033,7365887,7394498,7628266,7097044,6766437,5400236,4856206,5360981,8172306,8126000,8938556,8400102,7590172,8066498,7673545,7116489,6522466,5446466,5064648,5683474,4574108,2305372,5194076,7362400,7419854,7610737,7923905,7117901,6152460,5486010,4264807,5446854,8234794,7831843,7206673,7885361,7308461,7048481,6695905,6398153,6000072,5646858,4823630,5233359,7279073,6986937,7600470,8098162,6914791,7381156,7369580,6853944,6663305,6135048,5823069,6102161,8283808,8016456,9359447,9246242,8151646,8817230]
        rand1 = [0.5687,-0.9882,0.1189,-1.2601,-0.3911,1.9445,0.3316,-0.1481,0.4068,0.7671,0.8271,0.2716,-1.4072,0.4728,-0.9619,0.9173,-0.0821,-1.1588,0.0765,0.1755,-0.5259,-1.4256,1.3475,0.5346,0.471,-0.3013,0.7962,-0.7041,-0.2626,1.0618,-0.7738,-2.6074,-0.2967,1.7393,0.3519,1.176,1.2069,2.001,2.1573,0.1282,0.1068,-0.2681,1.0069,0.5927,-1.2703,-0.0711,-0.9,-0.0616,-1.3429,-0.0401,1.0748,-1.1614,-0.6819,-1.4115,0.0691,-1.0553,-0.93,1.2836,-1.7831,-0.7062,-1.0082,1.0524,1.5953,1.2455,0.8654,0.8777,-1.4663,-0.4333,-0.8127,-0.845,-0.948,-0.6094,-0.1344,0.9685,-0.1491,0.1436,1.7774,1.0366,0.8299,0.561,0.8791,0.7471,-1.6092,0.6296,-1.3406,-1.7664,-1.4931,-0.5876,-1.3118,0.4803,-0.2882,2.1569,-0.6655,-1.0178,0.8228,1.6798,2.3363,-0.6074,1.4136,2.3746,0.7793,-1.1287,0.6165,-0.4108,-0.2369,0.0369,-1.1097,-0.6431,1.3221,0.5657,-0.4914,-0.4554,-1.5849,0.4813,-1.2737,-0.0796,0.4004,-1.738,0.1925,1.1093,0.0209,0.6383,0.6414,-0.8735,-0.088,-0.9283,2.0551,-0.136,0.1777,0.8772,0.5376,-1.2647,1.071,0.2456,-1.0931,-0.0118,0.6261,-0.587,-1.2294,-0.4165,0.5345,1.0869,-0.9818,0.4787,-1.3789,1.3529,0.6653,-0.8275,-0.5914,-0.7355,0.0025,1.4563,-0.0898,-1.5065,0.4905,0.4267,1.5735,1.6162,0.0042,-0.8997,0.8872,0.2177,-0.2742,-0.0914,-0.9045,0.4791,0.9858,-0.5043,-0.8218,0.5795,1.1364,0.7795,0.2155,0.3003,1.335,1.1247,-0.6261,0.6944,0.7684,0.7753,-0.6865,0.9433,-0.8882,0.1489,0.8787,0.4825,1.6892,0.4575,0.0787,0.0675,-0.86,-0.914,-0.1587,-0.5791,-3.0869,0.3754,-1.598,-1.2995,-0.5107,0.0434]
        rand2 = [-0.1704,-0.031,-0.9051,1.3667,-0.6603,-1.2154,0.4385,0.0046,-0.901,-1.2074,0.967,1.5714,-1.7821,-0.8662,-0.6328,1.68,-0.5189,0.6465,0.2242,0.0035,-1.4844,0.9738,1.9551,2.4202,-0.5543,2.4926,-1.3705,-0.5917,0.3687,0.6026,1.3289,-1.2352,0.3733,-1.5046,-1.1465,-0.6998,1.1829,0.9636,-2.5403,-0.0889,0.222,-0.2371,-0.2622,-0.318,-0.7091,2.1513,-1.8727,1.9292,-0.5143,-1.1911,0.7576,0.0317,0.4863,1.3735,0.5418,0.7537,-0.6496,-0.686,-0.9757,-0.7936,2.1179,0.0297,0.8527,0.5862,0.3971,-0.1645,-0.0801,-1.5308,0.3307,1.0911,-0.1486,1.4192,-1.2795,0.1377,0.6074,0.4261,2.8731,-0.8682,0.5553,0.6402,0.2486,0.1287,0.4496,-0.1236,1.2351,1.5403,-1.9935,0.0496,-0.2966,-0.2954,0.3419,0.6887,2.1978,-0.0516,2.4479,1.0854,-0.6392,1.3028,0.0393,2.629,-1.354,-0.1778,-0.4331,0.747,0.987,0.7355,-1.0862,0.1334,-1.6203,-0.5428,-0.395,-1.3743,0.1074,0.9704,-0.477,-0.1549,0.7942,-0.8713,-0.2082,-0.1651,-0.1024,0.6153,-1.0785,0.5474,-0.3285,0.0196,0.0858,-0.8818,-0.6434,0.5494,0.2669,-0.9273,0.5372,1.3082,-1.0465,-0.827,-0.235,0.6867,0.5845,0.4367,0.4999,-1.3073,-0.5405,0.3379,0.2777,-1.6883,0.377,0.4937,-1.7551,0.083,0.9544,-1.031,0.0161,0.5916,0.385,-1.3268,1.0003,-0.1609,0.1423,1.4889,-0.8451,0.9358,1.5615,-0.9011,1.1147,0.3253,-0.0619,0.7079,-1.1104,-0.9596,0.2851,0.4034,-1.1073,-1.4975,1.1099,0.4102,1.2365,1.1653,-0.8865,-1.7562,-0.4068,0.2453,-1.6118,-1.3843,1.6611,2.1868,-0.002,-0.2606,0.4229,0.3741,-0.7955,-0.8958,-1.8156,-0.9431,-0.4636,-1.1189,1.3201,0.2129,-1.1911,-1.5737]
        rand3 = [0.4,-1.244,-0.6624,-0.2374,0.8301,0.1963,-1.0709,-2.1135,-0.9823,-0.4708,1.7067,2.0829,0.9164,-1.2108,0.95,-0.0411,1.2794,-0.4177,-1.4433,-0.6785,-0.3556,0.2837,-0.4542,1.2275,-1.4683,-0.2391,1.3763,0.0039,0.2075,-0.002,1.818,-0.217,1.3371,0.3491,-0.9266,0.1919,1.2281,0.1045,1.2826,-0.0476,-1.2573,-0.5801,-0.4852,-0.2036,0.1492,-1.223,-0.0156,-0.0776,-0.3095,-0.578,-0.8226,-0.1801,0.8687,-0.6018,0.5643,-0.5356,-0.133,0.3345,-0.8733,-0.1184,2.5991,-0.4902,-0.9866,-3.0948,-0.8492,0.0724,0.9559,0.693,-0.4897,-0.4258,0.5164,-0.121,-1.5062,0.5266,-1.5228,-0.7205,0.0551,1.0677,-0.0706,-0.3775,-0.7217,-1.6799,-0.3464,-0.7523,-1.509,0.3666,0.5706,-0.1025,-1.5335,0.054,0.5089,1.0493,-0.7767,-1.1604,-0.0672,1.5049,0.2447,-1.0308,-0.0407,-0.7553,1.1118,-0.5535,2.451,0.3446,0.8431,0.4375,-1.7314,-1.2065,-0.5337,3.4444,0.3097,-0.9857,-1.5802,-0.8664,0.6159,2.6515,1.2974,1.0753,1.4807,-0.9055,-0.6936,-0.1725,-0.1754,0.4146,-1.6657,-0.8932,0.0715,-0.1362,-1.7372,-0.2238,1.7457,-0.3934,0.35,0.523,1.5334,0.9833,0.0413,1.1863,-0.2761,-0.2063,0.0671,-0.5428,1.9861,0.5102,0.775,-0.1617,0.9135,0.0869,0.64,0.3292,-0.7374,0.3909,0.3401,-0.9863,0.5278,-0.4481,-0.6161,-0.9546,-1.4581,0.0495,1.1513,-0.5621,0.4348,0.3397,-0.0318,-1.1157,0.6585,-0.2495,-1.0561,-1.9686,0.4416,-1.5094,-2.0153,-0.5641,0.5587,0.1942,-1.8782,-1.8311,1.0107,-0.3177,-1.7795,0.5776,-0.8266,0.7934,0.3244,-0.4894,0.0459,-0.0275,1.0859,0.9312,-1.1304,-0.4712,0.8873,0.766,1.3654,0.0076,0.976,-0.166,-0.3933,0.597]
        % FRED TOTBUSIMNSA
        inventories = tse.TSeries(tse.mm(1991,1), [802948, 809329, 813301, 819247, 815688, 812610, 817899, 820061, 823912, 844117, 850772, 823633, 830472, 837696, 845466, 851007, 848150, 840682, 841820, 843790, 851014, 872794, 881832, 850662, 857823, 867791, 869132, 876216, 883463, 879098, 886582, 894296, 903536, 932673, 944083, 913178, 930073, 943250, 951783, 964551, 966416, 959054, 963639, 966512, 974748, 1005190, 1013264, 971548, 985288, 992520, 989270, 997607, 993342, 981384, 987780, 989675, 996161, 1026552, 1032049, 990236, 1001594, 1011593, 1010703, 1020615, 1018096, 1012936, 1016327, 1017650, 1029939, 1061105, 1068905, 1031141, 1042099, 1055958, 1060445, 1067950, 1060760, 1049957, 1053376, 1056507, 1067240, 1097690, 1107522, 1062675, 1071035, 1082979, 1090302, 1098322, 1094943, 1086975, 1091848, 1094423, 1107696, 1141338, 1159390, 1121998, 1134371, 1146568, 1150610, 1162620, 1162809, 1162473, 1162945, 1171166, 1178706, 1216296, 1229002, 1180188, 1191951, 1191439, 1186330, 1189533, 1180738, 1161695, 1152536, 1150828, 1152421, 1165237, 1157597, 1103923, 1111640, 1112071, 1109602, 1111506, 1108397, 1102590, 1106888, 1107788, 1123981, 1155466, 1163421, 1124357, 1133336, 1148853, 1152247, 1155995, 1143502, 1132545, 1127423, 1119164, 1132069, 1167310, 1176290, 1133494, 1142349, 1159588, 1172616, 1182818, 1181878, 1186159, 1194192, 1201482, 1211812, 1248972, 1269840, 1225450, 1245168, 1261228, 1272998, 1281111, 1273841, 1266265, 1259652, 1262073, 1279664, 1316722, 1332567, 1296279, 1314928, 1326292, 1342439, 1354566, 1361158, 1366616, 1371049, 1378410, 1394671, 1427827, 1440290, 1389464, 1404113, 1417759, 1421965, 1432810, 1434501, 1435032, 1437124, 1439626, 1460055, 1495048, 1510232, 1467827, 1492578, 1507570, 1508679, 1518447, 1511935, 1515048, 1527089, 1525299, 1528977, 1544889, 1530433, 1447083, 1439167, 1425061, 1406341, 1390417, 1365989, 1343414, 1331264, 1312360, 1318473, 1351866, 1364032, 1314711, 1324991, 1339537, 1349848, 1357098, 1352966, 1356614, 1370907, 1380956, 1408712, 1453296, 1466048, 1432436, 1455698, 1471379, 1492992, 1507258, 1515928, 1512044, 1521993, 1529029, 1538145, 1582704, 1590660, 1545609, 1567020, 1587969, 1597527, 1606183, 1603608, 1593978, 1609371, 1615986, 1640806, 1681384, 1687692, 1635359, 1666318, 1674942, 1676321, 1682798, 1669754, 1656544, 1666687, 1673769, 1696544, 1744996, 1754594, 1703784, 1729329, 1745613, 1754664, 1765601, 1761193, 1749824, 1761654, 1764051, 1781960, 1823893, 1828731, 1768620, 1786027, 1797721, 1802099, 1812342, 1802493, 1801416, 1806687, 1805867, 1827359, 1865936, 1862707, 1803264, 1818881, 1819586, 1830558, 1836272, 1827236, 1819262, 1819216, 1820815, 1841062, 1874260, 1890039, 1837538, 1859213, 1868841, 1875952, 1872678, 1865192, 1863610, 1867788, 1879852, 1899300, 1932109, 1944985, 1896032, 1927087, 1944782, 1944271, 1947393, 1938113, 1928497, 1937876, 1948180, 1973699, 2018525, 2019876, 1980546, 2019358, 2034293, 2032390, 2043268, 2034278, 2022725, 2028440, 2025575, 2040535, 2077337, 2074770, 2020662, 2038753, 2034414, 2026781, 1999651, 1935469, 1903697, 1907634, 1912619, 1944565, 1996118, 2008212, 1974406, 2009883, 2033227, 2039642, 2042900, 2041201, 2049889, 2071015, 2086983, 2132147, 2198902, 2235535, 2238164, 2295117, 2343973, 2404147, 2428332, 2447947, 2472266, 2477207, 2494999, 2522763, 2567129, 2573215, 2516894, 2538524, 2546010, 2554013, 2552240, 2534742, 2522767, 2511881, 2522326, 2554003])
    end

    properties (Access = private)
        PreviousX13Path
    end

    methods (TestClassSetup)
        function configureX13Binary(tc)
            tc.PreviousX13Path = tse.getoption('x13path');
            tse.setoption('x13path', char(tc.X13ExecutablePath));
        end
    end

    methods (TestClassTeardown)
        function restoreX13Binary(tc)
            tse.setoption('x13path', tc.PreviousX13Path);
        end
    end

    methods (TestMethodSetup)
        function requireConfiguredBinary(tc)
            x13path = string(tse.getoption('x13path'));
            tc.assumeTrue(x13path ~= tc.X13ExecutablePath || isfile(x13path), ...
                sprintf(['Configure TestX13Run.X13ExecutablePath in %s before running ', ...
                'the X13 end-to-end tests.'], mfilename('fullpath')));
            tc.assumeTrue(isfile(x13path), sprintf('Configured x13path does not exist: %s', x13path));
        end
    end

    methods (Access = private)
        function verifySeriesKeys(tc, res, keys)
            for i = 1:numel(keys)
                key = matlab.lang.makeValidName(keys{i});
                tc.verifyTrue(isfield(res.series, key), sprintf('Missing result series field: %s', key));
                if isfield(res.series, key)
                    value = res.series.(key);
                    tc.verifyTrue(isa(value, 'tse.TSeries') || isa(value, 'tse.MVTSeries'), ...
                        sprintf('Unexpected type for res.series.%s: %s', key, class(value)));
                end
            end
        end

        function verifyTableKeys(tc, res, keys)
            for i = 1:numel(keys)
                key = matlab.lang.makeValidName(keys{i});
                tc.verifyTrue(isfield(res.tables, key), sprintf('Missing result table field: %s', key));
                if isfield(res.tables, key)
                    tc.verifyTrue(isstruct(res.tables.(key)), ...
                        sprintf('Unexpected type for res.tables.%s: %s', key, class(res.tables.(key))));
                end
            end
        end

        function verifyOtherKeys(tc, res, keys)
            for i = 1:numel(keys)
                key = matlab.lang.makeValidName(keys{i});
                tc.verifyTrue(isfield(res.other, key), sprintf('Missing result other field: %s', key));
                if isfield(res.other, key)
                    if ismember(key, {'est', 'mdl', 'ipc', 'iac'})
                          tc.verifyTrue(ischar(res.other.(key)), ...
                            sprintf('Unexpected type for res.other.%s: %s', key, class(res.other.(key))));
                      
                    else
                          tc.verifyTrue(isstruct(res.other.(key)), ...
                            sprintf('Unexpected type for res.other.%s: %s', key, class(res.other.(key))));
                    end
                end
            end
        end

        function res = runSpec(tc, spec)
            res = tse.x13.run(spec, 'verbose', false, 'load', 'all');
            tc.verifyClass(res, 'tse.x13.X13result');
        end

        function values = fixtureArray(~, name)
            persistent cached
            if isempty(cached)
                cached = struct();
            end
            field = matlab.lang.makeValidName(name);
            if isfield(cached, field)
                values = cached.(field);
                return
            end
            content = TestX13Run.juliaRunFileContent();
            pattern = sprintf('(?ms)^%s\s*=\s*\[(.*?)\]', regexptranslate('escape', name));
            token = regexp(content, pattern, 'tokens', 'once');
            assert(~isempty(token), 'Fixture %s not found in Julia test file.', name);
            values = str2double(regexp(token{1}, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match'));
            cached.(field) = values;
        end

        function ts = inventoriesFixture(~)
            persistent inventories
            if ~isempty(inventories)
                ts = inventories;
                return
            end
            content = TestX13Run.juliaRunFileContent();
            token = regexp(content, '(?ms)^inventories\s*=\s*TSeries\(1991M1,\s*\[(.*?)\]\)', 'tokens', 'once');
            assert(~isempty(token), 'inventories fixture not found in Julia test file.');
            values = str2double(regexp(token{1}, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match'));
            inventories = tse.TSeries(tse.mm(1991,1), values(:));
            ts = inventories;
        end

        function path = juliaDataFile(tc, fileName)
            root = fileparts(fileparts(mfilename('fullpath')));
            path = fullfile(root, 'TimeSeriesEcon.jl', 'data', fileName);
            tc.assumeTrue(isfile(path), sprintf('Required Julia data file is missing: %s', path));
        end
    end

    methods (Static, Access = private)
        function content = juliaRunFileContent()
            persistent cached
            if isempty(cached)
                root = fileparts(fileparts(mfilename('fullpath')));
                cached = fileread(fullfile(root, 'TimeSeriesEcon.jl', 'test', 'test_x13run.jl'));
            end
            content = cached;
        end
    end

    methods (Test)
        function arima_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.qq(1950,1), mvsales(1:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly Grape Harvest"));
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rrs','rsd'});
            tc.verifyTableKeys(res, {'itr','ac2','acf','pcf'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(2,1,0,0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rrs','trn'});
            tc.verifyTableKeys(res, {'acf','acm','itr','pcf','rts','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'seasonal','const'}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rmx','rrs','rsd','trn'});
            tc.verifyTableKeys(res, {'acf','itr','pcf','rcm','rts','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.yy(1950), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Annual Olive Harvest"));
            tse.x13.arima(spec, tse.x13.ArimaModel({2},1,0));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rrs','rsd','a3'});
            tc.verifyTableKeys(res, {'itr','acf','ac2','rts','pcf'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', 'const', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,12));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rmx','rrs','rsd','trn'});
            tc.verifyTableKeys(res, {'itr','acf','pcf','sp0','spr','rts'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales", 'print', {'span','seriesplot'}));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all', 'print', {'aictransform','seriesconstant'});
            tse.x13.regression(spec, 'variables', {'const','seasonal'}, 'save', 'all');
            model = tse.x13.ArimaModel(tse.x13.ArimaSpec(1,1,0), tse.x13.ArimaSpec(1,0,0,3), tse.x13.ArimaSpec(0,0,1));
            tse.x13.arima(spec, model);
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rmx','rrs','rsd','trn'});
            tc.verifyTableKeys(res, {'acm','acf','itr','pcf','rcm','rts','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12), 'ma', [NaN, 1.0], 'fixma', [false, true]);
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rrs','rsd','trn'});
            tc.verifyTableKeys(res, {'acf','itr','pcf','rts','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function automdl_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.regression(spec, 'variables', {'seasonal','const'}, 'save', 'all');
            tse.x13.automdl(spec);
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','a3','fct'});
            tc.verifyTableKeys(res, {'d8b','rts','sp0','sp1','sp2'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(200:600)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.regression(spec, 'variables', 'td', 'save', 'all');
            tse.x13.automdl(spec, 'diff', [1 1], 'maxorder', [3 NaN]);
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.outlier(spec, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','a2','a3','ao','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','ira','otl','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','td','trn','fct','ftr'});
            tc.verifyTableKeys(res, {'ac2','acf','acm','d8b','pcf','rcm','rts','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function check_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1964,1), mvsales(150:300)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Retail Sales"));
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1967,6)), tse.x13.ls(tse.mm(1971,6)), tse.x13.easter(14)}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.check(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','ao','b1','hol','ls','otl','rmx','td','a3','chl','rrs'});
            tc.verifyTableKeys(res, {'ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            ts = tse.TSeries(tse.mm(1964,1), mvsales(150:650)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Warehouse clubs and supercenters"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(2000,3)), tse.x13.tc(tse.mm(2001,2))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 24, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.check(spec, 'acflimit', 2.0, 'qlimit', 0.05, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','a2','a3','ao','b1','fct','ftr','fvr','otl','ref','rmx','rrs','rsd','tc','td','trn'});
            tc.verifyTableKeys(res, {'ac2','acf','acm','itr','pcf','rcm','rts','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function estimate_run(tc)
            rand1 = tc.rand1;
            rand2 = tc.rand2;
            rand3 = tc.rand3;

            ts = tse.TSeries(tse.mm(1976,1), rand1(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.regression(spec, 'variables', 'seasonal', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1), 'ma', 0.25, 'fixma', true);
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rmx','rrs','rsd','a3'});
            tc.verifyTableKeys(res, {'itr','rcm','rts','acf','pcf','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1978,12), abs([rand2, rand1, rand3])');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Inventory"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'td', tse.x13.ao(tse.mm(1999,1))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(1,1,0,0,1,1));
            tse.x13.estimate(spec, 'tol', 1e-4, 'maxiter', 100, 'exact', 'ma', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','a2','a3','ao','b1','otl','ref','rmx','rrs','rsd','td','trn'});
            tc.verifyTableKeys(res, {'acm','itr','rcm','rts','ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            spec = tse.x13.newspec(tse.x13.series(tc.inventoriesFixture(), 'title', "Monthly Inventory"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.estimate(spec, 'file', fullfile(pwd, 'fixtures', 'reg1.mdl'), 'save', 'all', 'fix', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','a3'});
            tc.verifyTableKeys(res, {'itr','rts','acf','pcf','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function force_run(tc)
            mvsales = tc.mvsales;
            ts = tse.TSeries(tse.mm(1967,1), mvsales(250:400)');

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Exports of truck parts"));
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'save', 'all');
            tse.x13.force(spec, 'start', tse.x13.M(10), 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e6a','e7','e8','f1','p6a','paf','pe5','pe6','pe7','pe8','pir','psf','saa','tad','ffc'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});
        end

        function forecast_run(tc)
            mvsales = tc.mvsales;
            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', 'td', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.forecast(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','rmx','trn'});
            tc.verifyTableKeys(res, {'sp0'});
            tc.verifyOtherKeys(res, {'udg'});

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', 'td', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.outlier(spec, 'save', 'all');
            tse.x13.forecast(spec, 'maxlead', 24, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','a2','a3','ao','b1','fct','ftr','fts','fvr','otl','ref','rmx','rrs','rsd','td','trn'});
            tc.verifyTableKeys(res, {'acm','itr','oit','rcm','rts','acf','pcf','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function history_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1967,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Sales of livestock"));
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'save', 'all');
            tse.x13.history(spec, 'sadjlags', 2, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1969,7), mvsales(500:650)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Exports of leather goods"));
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.ls(tse.mm(1972,5)),tse.x13.ls(tse.mm(1976,10))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,1,1,0));
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.forecast(spec, 'save', 'all');
            tse.x13.history(spec, 'estimates', 'fcst', 'fstep', 1, 'start', tse.mm(1975,1), 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','b1','fce','fch','fct','ftr','fvr','ls','otl','ref','rmx','rrs','rsd','td','a3'});
            tc.verifyTableKeys(res, {'acm','itr','rcm','rot','rts','ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function identify_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.identify(spec, 'diff', [0 1], 'sdiff', [0 1], 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1','trn'});
            tc.verifyTableKeys(res, {'sp0'});
            tc.verifyOtherKeys(res, {'iac','ipc','udg'});

            ts = tse.TSeries(tse.qq(1963,1), mvsales(300:400)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly Sales"));
            tse.x13.regression(spec, 'variables', {tse.x13.ls(tse.qq(1971,1))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.identify(spec, 'diff', [0 1], 'sdiff', [0 1], 'maxlag', 16, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.check(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a19','b1','ls','otl','ref','rmx','rrs','rsd','a3'});
            tc.verifyTableKeys(res, {'ac2','acf','acm','itr','pcf','rts'});
            tc.verifyOtherKeys(res, {'est','iac','ipc','lks','mdl','udg'});
        end

        function outlier_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(250:400)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.outlier(spec, 'lsrun', 5, 'types', {'ao','ls'}, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a19','b1','fts','a3','ls','otl','rrs'});
            tc.verifyTableKeys(res, {'oit','ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            altered = mvsales(1:250);
            altered(140:150) = altered(140:150) / 100;
            altered(151:end) = altered(151:end) * 3;
            ts = tse.TSeries(tse.mm(1976,1), altered(:));
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales", 'span', tse.mm(1980,1):tse.mm(1992,12)));
            tse.x13.arima(spec, tse.x13.ArimaSpec(0,1,1), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.outlier(spec, 'critical', [3.0 4.5 4.0], 'types', 'all', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a19','b1','fts','ref','rrs','rsd','a3','ao','ls','otl','tc'});
            tc.verifyTableKeys(res, {'acm','itr','oit','rcm','rts','ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function pickmdl_run(tc)
            mvsales = tc.mvsales;
            models1 = [ ...
                tse.x13.ArimaModel(0,1,1,0,0,1, 'default', true), ...
                tse.x13.ArimaModel(0,1,2,0,0,1), ...
                tse.x13.ArimaModel(2,1,0,0,0,1), ...
                tse.x13.ArimaModel(0,2,2,0,0,1), ...
                tse.x13.ArimaModel(2,1,2,0,0,1) ...
            ];
            models2 = [ ...
                tse.x13.ArimaModel(0,1,1,0,1,1, 'default', true), ...
                tse.x13.ArimaModel(0,1,2,0,1,1), ...
                tse.x13.ArimaModel(2,1,0,0,1,1), ...
                tse.x13.ArimaModel(0,2,2,0,1,1), ...
                tse.x13.ArimaModel(2,1,2,0,1,1) ...
            ];

            ts = tse.TSeries(tse.mm(1976,1), mvsales(50:250)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'td','seasonal'}, 'save', 'all');
            tse.x13.pickmdl(spec, models1, 'mode', 'fcst');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','td','trn','fct','ftr'});
            tc.verifyTableKeys(res, {'acm','d8b','rcm','rts','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(100:200)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', 'td', 'save', 'all');
            tse.x13.pickmdl(spec, models2, 'mode', 'fcst', 'method', 'first', 'fcstlim', 20, 'qlim', 10, 'overdiff', 0.99, 'identify', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.outlier(spec, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','td','trn','fct','ftr'});
            tc.verifyTableKeys(res, {'acm','d8b','rcm','rts','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(50:250)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'td','seasonal'}, 'save', 'all');
            tse.x13.pickmdl(spec, 'file', fullfile(pwd, 'fixtures','pickmdl.mdl'), 'mode', 'fcst');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','td','trn','fct','ftr'});
            tc.verifyTableKeys(res, {'acm','d8b','rcm','rts','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});
        end

        function regression_run(tc)
            mvsales = tc.mvsales;
            rand1 = tc.rand1;
            rand2 = tc.rand2;
            
            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Sales"));
            tse.x13.regression(spec, 'variables', {'const','seasonal'}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rmx','rrs','rsd','a3'});
            tc.verifyTableKeys(res, {'itr','rcm','rts','acf','pcf','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(100:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Irregular Component of Monthly Sales"));
            tse.x13.regression(spec, 'variables', {'const', tse.x13.sincos([4 5])}, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.spectrum(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rmx','rrs','rsd','a3'});
            tc.verifyTableKeys(res, {'itr','rcm','sp0','spr','acf','pcf'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1970,1), mvsales(501:550)');
            mv = tse.MVTSeries(tse.mm(1960,1), ["temp","precip"], [rand1(1:171)', rand2(1:171)']);
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Monthly Riverflow"));
            tse.x13.regression(spec, 'variables', {'seasonal','const'}, 'data', mv, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(3,0,0,0,0,0));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','ref','rmx','rrs','rsd','usr','a3'});
            tc.verifyTableKeys(res, {'acm','itr','rcm','rts','acf','pcf','sp0','spr'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1980,1), mvsales(101:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Exports of pasta products"));
            tse.x13.regression(spec, 'variables', {'const','td'}, 'save', 'all');
            tse.x13.automdl(spec);
            tse.x13.x11(spec, 'mode', 'add', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','rmx','tad','td','a3','fct','rrs'});
            tc.verifyTableKeys(res, {'d8b','acf','pcf','sp0','sp1','sp2','spr'});
            tc.verifyOtherKeys(res, {'est','udg'});
        end

        function seats_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1987,1), mvsales(101:550)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Exports of truck parts"));
            tse.x13.transform(spec, 'func', 'auto', 'save', 'all');
            tse.x13.regression(spec, 'aictest', 'td', 'save', 'all');
            tse.x13.automdl(spec);
            tse.x13.outlier(spec, 'types', {'ao','ls','tc'}, 'save', 'all');
            tse.x13.forecast(spec, 'maxlead', 36, 'save', 'all');
            tse.x13.seats(spec, 'save', 'all');
            res = tc.runSpec(spec);
            % some keys missing from specific X13 versions: tbs
            tc.verifySeriesKeys(res, {'a3','afd','ao','cyc','dor','dsa','dtr','fct','ftr','fvr','ltt','otl','psc','psi','pss','rmx','s10','s11','s12','s13','s14','s16','s18','sfd','ssm','td','tfd','trn','yfd','a1','a18','a19','ase','b1','cse','rrs','se2','se3','sse','tse'});
            % tc.verifySeriesKeys(res, {'tbs','a3','afd','ao','cyc','dor','dsa','dtr','fct','ftr','fvr','ltt','otl','psc','psi','pss','rmx','s10','s11','s12','s13','s14','s16','s18','sfd','ssm','td','tfd','trn','yfd','a1','a18','a19','ase','b1','cse','rrs','se2','se3','sse','tse'});
            % some keys missing from specific X13 versions: rog
            tc.verifyTableKeys(res, {'wkf','ac2','acf','pcf','s1s','s2s','sp0','spr','st0','str','t1s','t2s'});
            % tc.verifyTableKeys(res, {'wkf','ac2','acf','pcf','s1s','s2s','sp0','spr','st0','str','t1s','t2s','rog'});
            tc.verifyOtherKeys(res, {'mdc','est','udg'});

            if ~ispc
                ts = tse.fconvert(tse.Quarterly(), tse.TSeries(tse.mm(1990,1), flipud(mvsales(1:250)')));
                spec = tse.x13.newspec(tse.x13.series(ts));
                tse.x13.transform(spec, 'func', 'log');
                tse.x13.regression(spec, 'aictest', 'td');
                tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
                tse.x13.forecast(spec, 'maxlead', 12);
                tse.x13.seats(spec, 'finite', true);
                tse.x13.history(spec, 'estimates', {'sadj','trend'});
                res = tc.runSpec(spec);
                % some keys missing from specific X13 versions: tbs
                tc.verifySeriesKeys(res, {'a3','afd','dor','dsa','dtr','fct','ftr','s10','s11','s12','s13','s16','s18','sae','sfd','ssm','tfd','tre','a1','ase','b1','se2','se3','sse','tse'});
                % tc.verifySeriesKeys(res, {'tbs','a3','afd','dor','dsa','dtr','fct','ftr','s10','s11','s12','s13','s16','s18','sae','sfd','ssm','tfd','tre','a1','ase','b1','se2','se3','sse','tse'});
                % some keys missing from specific X13 versions: rog
                tc.verifyTableKeys(res, {'fac','faf','ftc','ftf','gac','gaf','gtc','gtf','tac','ttc','ac2','acf','pcf'});
                % tc.verifyTableKeys(res, {'fac','faf','ftc','ftf','gac','gaf','gtc','gtf','tac','ttc','ac2','acf','pcf','rog'});
                tc.verifyOtherKeys(res, {'est','udg'});
            end

            ts = tse.TSeries(tse.mm(1995,1), mvsales(50:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Model based adjustment of Bimonthly exports"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.outlier(spec, 'types', {'ao','ls','tc'}, 'save', 'all');
            tse.x13.forecast(spec, 'maxlead', 18, 'save', 'all');
            tse.x13.seats(spec, 'save', 'all');
            res = tc.runSpec(spec);
            % some keys missing from specific X13 versions: tbs, cyc, ltt
            tc.verifySeriesKeys(res, {'a3','afd','dor','dsa','dtr','fct','ftr','fts','psi','pss','s10','s11','s12','s13','s16','s18','sfd','ssm','tfd','trn','a1','ase','b1','se2','se3','sse','tse'});
            % tc.verifySeriesKeys(res, {'tbs','a3','afd','cyc','dor','dsa','dtr','fct','ftr','fts','ltt','psi','pss','s10','s11','s12','s13','s16','s18','sfd','ssm','tfd','trn','a1','ase','b1','se2','se3','sse','tse'});
            % some keys missing from specific X13 versions: rog, ac2
            tc.verifyTableKeys(res, {'oit','wkf','acf','pcf'});
            % tc.verifyTableKeys(res, {'oit','wkf','ac2','acf','pcf','rog'});
            tc.verifyOtherKeys(res, {'mdc','est','udg'});

            ts = tse.TSeries(tse.qq(1990,1), mvsales(100:150)');
            spec = tse.x13.newspec(tse.x13.series(ts));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'aictest', 'td', 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 12, 'save', 'all');
            tse.x13.seats(spec, 'tabtables', {'xo','n','s','p'}, 'printphtrf', false, 'save', 'all');
            res = tc.runSpec(spec);
            % some keys missing from specific X13 versions: tbs, cyc, ltt
            tc.verifySeriesKeys(res, {'a3','afd','dor','dsa','dtr','fct','ftr','psi','pss','rmx','s10','s11','s12','s13','s16','s18','sfd','ssm','tfd','trn','a1','ase','b1','se2','se3','sse','tse'});
            % tc.verifySeriesKeys(res, {'tbs','a3','afd','cyc','dor','dsa','dtr','fct','ftr','ltt','psi','pss','rmx','s10','s11','s12','s13','s16','s18','sfd','ssm','tfd','trn','a1','ase','b1','se2','se3','sse','tse'});
            % some keys missing from specific X13 versions: rog, ac2
            tc.verifyTableKeys(res, {'wkf','acf','pcf'});
            % tc.verifyTableKeys(res, {'wkf','ac2','acf','pcf','rog'});
            tc.verifyOtherKeys(res, {'mdc','est','udg'});
        end

        function slidingspans_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Tourist"));
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'save', 'all');
            tse.x13.slidingspans(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.fconvert(tse.Quarterly(), tse.TSeries(tse.mm(1967,1), flipud(mvsales(1:250)')));
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly stock prices on NASDAQ"));
            tse.x13.x11(spec, 'seasonalma', {'s3x9','s3x9','s3x5','s3x5'}, 'trendma', 7, 'mode', 'logadd');
            tse.x13.slidingspans(spec, 'cutseas', 5.0, 'cutchng', 5.0);
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','c17','c20','chs','d10','d11','d12','d13','d16','d8','d9','e1','e18','e2','e3','sfs','ycs'});
            tc.verifyTableKeys(res, {'d8b'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1980,1), mvsales(301:500)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Number of employed machinists - X-11"));
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.rp(tse.mm(1982,5), tse.mm(1982,10))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.outlier(spec, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.check(spec, 'save', 'all');
            tse.x13.forecast(spec, 'save', 'all');
            tse.x13.x11(spec, 'mode', 'add', 'save', 'all');
            tse.x13.slidingspans(spec, 'outlier', 'keep', 'length', 144, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','chs','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','fct','ftr','fts','fvr','ls','otl','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','sfs','tad','tal','td','ycs','a3'});
            tc.verifyTableKeys(res, {'ac2','acf','acm','d8b','itr','oit','pcf','rcm','rts','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1980,1), mvsales(151:450)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Number of employed machinists - Seats"));
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.rp(tse.mm(1982,5), tse.mm(1982,10))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.outlier(spec, 'save', 'all');
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.check(spec, 'save', 'all');
            tse.x13.forecast(spec, 'save', 'all');
            tse.x13.seats(spec, 'save', 'all');
            tse.x13.slidingspans(spec, 'outlier', 'keep', 'length', 144, 'save', 'all');
            res = tc.runSpec(spec);
            % some keys missing from specific X13 versions: tbs
            tc.verifySeriesKeys(res, {'a1','a18','a19','ao','b1','chs','fct','ftr','fts','fvr','ls','otl','ref','rmx','rrs','rsd','sfs','td','ycs','a3','afd','ase','cse','dor','dsa','dtr','s10','s11','s12','s13','s14','s16','s18','se2','se3','sfd','sse','ssm','tfd','tse','yfd'});
            % tc.verifySeriesKeys(res, {'tbs','a1','a18','a19','ao','b1','chs','fct','ftr','fts','fvr','ls','otl','ref','rmx','rrs','rsd','sfs','td','ycs','a3','afd','ase','cse','dor','dsa','dtr','s10','s11','s12','s13','s14','s16','s18','se2','se3','sfd','sse','ssm','tfd','tse','yfd'});
            tc.verifyTableKeys(res, {'ac2','acf','acm','itr','oit','pcf','rcm','rts','s1s','s2s','sp0','spr','st0','str','t1s','t2s'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1975,1), mvsales(51:300)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Cheese sales in Wisconsin"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'const','seasonal','tdnolpyear'}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(3,1,0));
            tse.x13.forecast(spec, 'maxlead', 60, 'save', 'all');
            tse.x13.x11(spec, 'appendfcst', true, 'save', 'all');
            tse.x13.slidingspans(spec, 'fixmdl', false, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a3','ads','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','chs','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','fct','ftr','fvr','paf','pe5','pe6','pe7','pe8','pir','psf','rmx','sfs','tad','td','tds','trn','ycs','rrs'});
            tc.verifyTableKeys(res, {'d8b','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            ts = tse.fconvert(tse.Quarterly(), tse.TSeries(tse.mm(1967,1), flipud(mvsales(1:250)')));
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly stock prices on NASDAQ sp6"));
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.slidingspans(spec, 'length', 40, 'numspans', 3);
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','c17','c20','chs','d10','d11','d12','d13','d16','d8','d9','e1','e18','e2','e3','sfs','ycs'});
            tc.verifyTableKeys(res, {'d8b'});
            tc.verifyOtherKeys(res, {'udg'});
        end

        function spectrum_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:50)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Klaatu"));
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'trendma', 23, 'save', 'all');
            tse.x13.spectrum(spec, 'logqs', true, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1967,1), mvsales(51:450)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Spectrum analysis of Building Permits Series"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.spectrum(spec, 'start', tse.mm(1987,1), 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1'});
            tc.verifyTableKeys(res, {'sp0','st0'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1967,1), mvsales(101:250)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "TOTAL ONE-FAMILY Housing Starts"));
            tse.x13.x11(spec, 'seasonalma', {'s3x9'}, 'title', "Composite adj. of 1-Family housing starts", 'save', 'all');
            tse.x13.spectrum(spec, 'type', 'periodogram', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1988,1), mvsales(201:350)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.S. Retail Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {'td',tse.x13.easter(8),tse.x13.labor(8)}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 60, 'save', 'all');
            tse.x13.spectrum(spec, 'logqs', true, 'qcheck', true, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','chl','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','fct','ftr','fvr','hol','paf','pe5','pe6','pe7','pe8','pir','psf','rmx','tad','td','trn','rrs'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','spr','str','ac2','acf','pcf','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'est','udg'});
        end

        function transform_run(tc)
            mvsales = tc.mvsales;
            rand1 = tc.rand1;

            ts = tse.TSeries(tse.mm(1967,1), mvsales(51:200)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Transform example"));
            tse.x13.transform(spec, 'data', tse.TSeries(tse.mm(1967,1), rand1(1:150)'.^2), 'mode', 'ratio', 'adjust', 'lom', 'func', 'log', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a2p','b1'});
            tc.verifyTableKeys(res, {'sp0','st0'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.qq(1997,1), mvsales(101:300)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Transform example"));
            tse.x13.transform(spec, 'constant', 45.0, 'func', 'auto', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a1c','b1'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1980,1), mvsales(301:400)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.S. Retail Sales --- Current Dollars"));
            tse.x13.transform(spec, 'func', 'log', 'data', tse.TSeries(tse.mm(1970,1), (0.1:0.1:23.0)'), 'title', "Consumer Price Index", 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a2','a2p','b1'});
            tc.verifyTableKeys(res, {'sp0','st0'});
            tc.verifyOtherKeys(res, {'udg'});

            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.S. Retail Sales --- Current Dollars"));
            tse.x13.transform(spec, 'func', 'log', 'data', tse.TSeries(tse.mm(1970,1), (0.1:0.1:23.0)'), 'title', "Consumer Price Index", 'type', 'temporary', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a2','a2t','b1'});
            tc.verifyTableKeys(res, {'sp0','st0'});
            tc.verifyOtherKeys(res, {'udg'});

            if ~ispc
                ts = tse.TSeries(tse.qq(1901,1), mvsales(1:50)');
                spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Annual Rainfall"));
                tse.x13.transform(spec, 'power', 0.3333);
                res = tc.runSpec(spec);
                tc.verifySeriesKeys(res, {'a1','b1'});
                tc.verifyOtherKeys(res, {'udg'});
            end

            ts = tse.TSeries(tse.mm(1978,1), mvsales(401:550)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.K. Retail Sales"));
            tse.x13.transform(spec, 'func', 'auto', 'aicdiff', 0.0, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1'});
            tc.verifyTableKeys(res, {'sp0','st0'});
            tc.verifyOtherKeys(res, {'udg'});
        end

        function x11_run(tc)
            mvsales = tc.mvsales;
            rand1 = tc.rand1;
            rand2 = tc.rand2;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:250)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Klaatu"));
            tse.x13.x11(spec, 'save', 'all');
            tse.x13.spectrum(spec, 'logqs', true, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(201:450)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Klaatu"));
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'trendma', 23, 'save', 'all');
            tse.x13.x11regression(spec, 'variables', 'td', 'aictest', 'td', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b14','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c14','c16','c17','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xrm'});
            tc.verifyTableKeys(res, {'d8b','rcm','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            if ~ispc
                ts = tse.TSeries(tse.qq(1967,1), mvsales(250:500)');
                spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly housing starts"));
                tse.x13.x11(spec, 'seasonalma', {'s3x3','s3x3','s3x5','s3x5'}, 'trendma', 7, 'save', 'all');
                res = tc.runSpec(spec);
                tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
                tc.verifyTableKeys(res, {'d8b'});
                tc.verifyOtherKeys(res, {'udg'});
            end

            ts = tse.TSeries(tse.mm(1969,7), mvsales(301:550)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Exports of leather goods"));
            tse.x13.regression(spec, 'variables', {'const','td',tse.x13.ls(tse.mm(1972,5)),tse.x13.ls(tse.mm(1976,10))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,1,1,0));
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.forecast(spec, 'maxlead', 0, 'save', 'all');
            tse.x13.x11(spec, 'mode', 'add', 'sigmalim', [2.0 3.5], 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a19','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','ls','otl','paf','pe5','pe6','pe7','pe8','pir','psf','ref','rmx','rrs','rsd','tad','tal','td','a3'});
            tc.verifyTableKeys(res, {'acm','d8b','itr','rcm','rts','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','lks','mdl','udg'});

            ts = tse.TSeries(tse.mm(1985,1), mvsales(201:450)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Unit Auto Sales"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            nobs = numel(ts.values) + 24;
            sale88 = zeros(nobs, 1); sale90 = zeros(nobs, 1);
            i88 = tse.TSeries(tse.mm(1984,1), sale88); i90 = tse.TSeries(tse.mm(1984,1), sale90);
            i88(tse.mm(1988,3):tse.mm(1988,11)) = 1.0;
            i90(tse.mm(1990,2):tse.mm(1990,7)) = 1.0;
            mv = tse.MVTSeries(tse.mm(1984,1), ["sale88","sale90"], [i88.values, i90.values]);
            tse.x13.regression(spec, 'variables', {'const','td'}, 'data', mv, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaSpec(3,1,0), tse.x13.ArimaSpec(0,1,1,12));
            tse.x13.forecast(spec, 'maxlead', 12, 'maxback', 12, 'save', 'all');
            tse.x13.x11(spec, 'title', ["Unit Auto Sales"; "Adjusted for special sales in 1988, 1990"], 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a18','a2','a3','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','bct','btr','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','fct','ftr','fvr','paf','pe5','pe6','pe7','pe8','pir','psf','rmx','tad','td','trn','usr','rrs'});
            tc.verifyTableKeys(res, {'d8b','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(201:350)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "NORTHEAST ONE FAMILY Housing Starts"));
            tse.x13.transform(spec, 'func', 'log', 'save', 'all');
            tse.x13.regression(spec, 'variables', {tse.x13.ao(tse.mm(1976,2)),tse.x13.ao(tse.mm(1978,2)),tse.x13.ls(tse.mm(1980,2)),tse.x13.ls(tse.mm(1982,11)),tse.x13.ao(tse.mm(1984,2))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,2,0,1,1));
            tse.x13.forecast(spec, 'maxlead', 60, 'save', 'all');
            tse.x13.x11(spec, 'seasonalma', 's3x9', 'title', "Adjustment of 1 family housing starts", 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a19','a3','ao','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','fct','ftr','fvr','ira','ls','otl','paf','pe5','pe6','pe7','pe8','pir','psf','rmx','tad','tal','trn','rrs'});
            tc.verifyTableKeys(res, {'d8b','ac2','acf','pcf','sp0','sp1','sp2','spr','st0','st1','st2','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(51:200)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Trend for NORTHEAST ONE FAMILY Housing Starts"));
            tse.x13.transform(spec, 'func', 'auto', 'save', 'all');
            tse.x13.regression(spec, 'variables', {tse.x13.ls(tse.mm(1980,2)),tse.x13.ls(tse.mm(1982,11))}, 'save', 'all');
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.forecast(spec, 'save', 'all');
            tse.x13.x11(spec, 'type', 'trend', 'trendma', 13, 'sigmalim', [0.7 1.0], 'title', "Updated Dagum (1996) trend of 1 family housing starts", 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a19','a3','b1','b11','b13','b17','b2','b20','b3','b6','b7','b8','c1','c11','c13','c17','c2','c20','c4','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e7','e8','f1','fct','ftr','fvr','ls','otl','paf','pe5','pe7','pe8','pir','psf','rmx','tad','tal','trn','rrs'});
            tc.verifyTableKeys(res, {'d8b','ac2','acf','pcf','sp0','spr','st0','str'});
            tc.verifyOtherKeys(res, {'est','udg'});

            ts = tse.TSeries(tse.mm(1978,1), rand2(:));
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.K. Retail Sales"));
            tse.x13.transform(spec, 'func', 'auto', 'aicdiff', 0.0, 'save', 'all');
            tse.x13.x11(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1978,1), rand1(:));
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Total U.K. Retail Sales"));
            tse.x13.transform(spec, 'func', 'auto', 'aicdiff', 0.0, 'save', 'all');
            tse.x13.x11(spec, 'calendarsigma', 'select', 'sigmavec', [tse.x13.M(1), tse.x13.M(2), tse.x13.M(12)], 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b17','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c17','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(1:250)');
            spec = tse.x13.newspec(ts);
            tse.x13.x11(spec, 'save', {'fsd','fad'}, 'mode', 'pseudoadd');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'fsd','fad'});
        end

        function x11regression_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1976,1), mvsales(151:300)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Westus"));
            tse.x13.x11(spec, 'save', 'all');
            tse.x13.x11regression(spec, 'variables', 'td', 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b14','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c14','c16','c17','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xrm'});
            tc.verifyTableKeys(res, {'d8b','rcm','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1976,1), mvsales(51:250)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Westus"));
            tse.x13.x11(spec, 'save', 'all');
            tse.x13.x11regression(spec, 'variables', 'td', 'aictest', {'td','easter'}, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c16','c17','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xrm'});
            tc.verifyTableKeys(res, {'d8b','rcm','xoi','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1985,1), mvsales(101:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Ukclothes"));
            tse.x13.x11(spec, 'save', 'all');
            mv = tse.MVTSeries(tse.mm(1980,1), ["easter1","easter2"], [(0.1:0.1:12.2)', (12.2:-0.1:0.1)']);
            tse.x13.x11regression(spec, 'variables', 'td', 'usertype', 'holiday', 'critical', 4.0, 'data', mv, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','bxh','c1','c10','c11','c13','c16','c17','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xhl','xrm'});
            tc.verifyTableKeys(res, {'d8b','rcm','xoi','sp0','sp1','sp2'});
            tc.verifyOtherKeys(res, {'udg'});

            ts = tse.TSeries(tse.mm(1980,1), mvsales(251:350)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "nzstarts"));
            tse.x13.x11(spec, 'save', 'all');
            tse.x13.x11regression(spec, 'variables', 'td', 'tdprior', [1.4 1.4 1.4 1.4 1.4 0.0 0.0], 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a4','b1','b10','b11','b13','b14','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','c1','c10','c11','c13','c14','c16','c17','c18','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xrm'});
            tc.verifyTableKeys(res, {'d8b','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});

            if ~ispc
                ts = tse.TSeries(tse.qq(1964,1), mvsales(151:300)');
                spec = tse.x13.newspec(tse.x13.series(ts, 'title', "MIDWEST ONE FAMILY Housing Starts", 'span', tse.qq(1964,1):tse.qq(1989,3)));
                tse.x13.x11(spec);
                tse.x13.x11regression(spec, 'variables', {'td', tse.x13.easter(8)}, 'b', [0.4453 0.8550 -0.3012 0.2717 -0.1705 0.0983 -0.0082], 'fixb', [true true true true true true false]);
                res = tc.runSpec(spec);
                tc.verifySeriesKeys(res, {'a1','b1','c16','c17','c20','d10','d11','d12','d13','d16','d18','d8','d9','e1','e18','e2','e3','xhl'});
                tc.verifyTableKeys(res, {'d8b'});
                tc.verifyOtherKeys(res, {'udg'});
            end

            ts = tse.TSeries(tse.mm(1967,1), mvsales(101:400)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Motor Home Sales", 'span', tse.x13.Span(tse.mm(1972,1))));
            tse.x13.x11(spec, 'seasonalma', 'x11default', 'sigmalim', [1.8 2.8], 'appendfcst', true, 'save', 'all');
            tse.x13.x11regression(spec, 'variables', {tse.x13.td(tse.mm(1990,1)), tse.x13.easter(8), tse.x13.labor(10), tse.x13.thank(10)}, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','b1','b10','b11','b13','b16','b17','b19','b2','b20','b3','b5','b6','b7','b8','bxh','c1','c10','c11','c13','c16','c17','c19','c2','c20','c4','c5','c6','c7','d1','d10','d11','d12','d13','d16','d18','d2','d4','d5','d6','d7','d8','d9','e1','e11','e18','e2','e3','e5','e6','e7','e8','f1','paf','pe5','pe6','pe7','pe8','pir','psf','tad','xhl','xrm'});
            tc.verifyTableKeys(res, {'d8b','rcm','xoi','sp0','sp1','sp2','st0','st1','st2'});
            tc.verifyOtherKeys(res, {'udg'});
        end

        function failed_run(tc)
            mvsales = tc.mvsales;

            % For some reason this works with some versions of X13
            % ts = tse.TSeries(tse.mm(1976,1), mvsales(51:200)');
            % spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Westus"));
            % tse.x13.x11(spec, 'save', 'all');
            % tse.x13.x11regression(spec, 'variables', 'td', 'aictest', {'td','easter'});
            % tc.verifyError(@() tse.x13.run(spec, 'verbose', false), 'tseries:noMatch');

            ts = tse.TSeries(tse.qq(1967,1), mvsales(1:350)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly stock prices on NASDAQ"));
            tse.x13.x11(spec, 'seasonalma', 's3x9');
            tse.x13.slidingspans(spec, 'length', 40, 'numspans', 3);
            tc.verifyError(@() tse.x13.run(spec, 'verbose', false, 'load', 'all'), 'tseries:noMatch');
        end

        function string_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.qq(1950,1), mvsales(1:150)');
            spec = tse.x13.newspec(tse.x13.series(ts, 'title', "Quarterly Grape Harvest"));
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            tse.x13.x13write(spec);
            res = tse.x13.run(spec.string, tse.Quarterly(), 'verbose', false, 'load', 'all');
            tc.verifyClass(res, 'tse.x13.X13result');
            tc.verifySeriesKeys(res, {'a1','a3','b1','ref','rrs','rsd'});
            tc.verifyTableKeys(res, {'itr','ac2','acf','pcf'});
        end

        function missing_values_run(tc)
            mvsales = tc.mvsales;

            missingTs = tse.TSeries(tse.qq(1990,1), double(mvsales(1:150)'));
            missingTs(tse.qq(1994,1):tse.qq(1994,4)) = NaN;
            tc.verifyError(@() tse.x13.series(missingTs, 'title', "Quarterly Grape Harvest"), 'tseries:noMatch');

            tc.assumeFalse(ispc, 'Missing-value X13 run example is skipped on Windows, matching the Julia suite.');
            xts = tse.x13.series(missingTs, 'title', "Quarterly Grape Harvest", 'missingcode', -99999.0);
            spec = tse.x13.newspec(xts);
            tse.x13.arima(spec, tse.x13.ArimaModel(0,1,1));
            tse.x13.estimate(spec, 'save', 'all');
            res = tc.runSpec(spec);
            tc.verifySeriesKeys(res, {'a1','a3','b1'});
        end

        function deseasonalize_run(tc)
            mvsales = tc.mvsales;

            ts = tse.TSeries(tse.mm(1967,1), double(mvsales(101:400)'));
            out = tse.x13.deseasonalize(ts);
            tc.verifyClass(out, 'tse.TSeries');
            tc.verifyEqual(tse.rangeof(out), tse.rangeof(ts));

            spec = tse.x13.newspec(ts, 'x11', tse.x13.x11('save', 'd11'));
            res = tc.runSpec(spec);
            tc.verifyEqual(out.values, res.series.d11.values, 'AbsTol', 1e-10);
        end
    end
end