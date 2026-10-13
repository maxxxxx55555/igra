# Measured deltas of the density frames (Session 23)

Written by `python tools/qa_sim/density_measure.py f2e628a --write docs/DENSITY_MEASURED.md` from the pairs of `docs/stills/density` (the same run and the same code: `before` has the district's dressing node hidden, `after` shows it).
Luminance is Rec. 709 on 0..1, saturation the HSV S of the pixels brighter than 0.05, contrast the standard deviation of the luminance, over the frame without the parts the HUD still draws; changed share is the part of the pixels
whose luminance differs by 0.05 or more. 55 pairs.

| District | View | Luminance before | after | Saturation before | after | Contrast before | after | Changed share |
|---|---|---|---|---|---|---|---|---|
| gas_station | 01_dark | 0.1983 | 0.1956 | 0.147 | 0.146 | 0.2106 | 0.2083 | 3.6 % |
| gas_station | 02_rest | 0.1737 | 0.1849 | 0.118 | 0.131 | 0.1725 | 0.1885 | 12.8 % |
| gas_station | 03_street | 0.1533 | 0.1579 | 0.108 | 0.110 | 0.1642 | 0.1754 | 8.1 % |
| gas_station | 04_block | 0.1466 | 0.1487 | 0.115 | 0.110 | 0.1360 | 0.1412 | 6.7 % |
| gas_station | 05_skyline | 0.1488 | 0.1529 | 0.113 | 0.114 | 0.1530 | 0.1611 | 5.4 % |
| hospital | 01_dark | 0.1877 | 0.1848 | 0.167 | 0.170 | 0.1989 | 0.1951 | 2.7 % |
| hospital | 02_rest | 0.1418 | 0.1635 | 0.212 | 0.186 | 0.1172 | 0.1575 | 18.3 % |
| hospital | 03_street | 0.1442 | 0.1486 | 0.159 | 0.157 | 0.1390 | 0.1496 | 6.0 % |
| hospital | 04_block | 0.1520 | 0.1556 | 0.206 | 0.210 | 0.1399 | 0.1467 | 4.4 % |
| hospital | 05_skyline | 0.1368 | 0.1415 | 0.160 | 0.159 | 0.1307 | 0.1412 | 5.0 % |
| industrial | 01_dark | 0.1798 | 0.1770 | 0.156 | 0.154 | 0.1812 | 0.1770 | 7.2 % |
| industrial | 02_rest | 0.1139 | 0.1360 | 0.126 | 0.117 | 0.0373 | 0.0786 | 20.7 % |
| industrial | 03_street | 0.1715 | 0.1499 | 0.111 | 0.128 | 0.1697 | 0.1187 | 19.0 % |
| industrial | 04_block | 0.1858 | 0.1601 | 0.122 | 0.181 | 0.1807 | 0.1281 | 22.7 % |
| industrial | 05_skyline | 0.1704 | 0.1458 | 0.119 | 0.161 | 0.1679 | 0.1082 | 19.1 % |
| park | 01_dark | 0.2093 | 0.2066 | 0.139 | 0.140 | 0.2385 | 0.2353 | 3.0 % |
| park | 02_rest | 0.1433 | 0.1761 | 0.132 | 0.109 | 0.1133 | 0.1798 | 19.6 % |
| park | 03_street | 0.1515 | 0.1561 | 0.100 | 0.100 | 0.1643 | 0.1737 | 6.8 % |
| park | 04_block | 0.1479 | 0.1535 | 0.122 | 0.122 | 0.1526 | 0.1615 | 4.7 % |
| park | 05_skyline | 0.1477 | 0.1496 | 0.103 | 0.104 | 0.1636 | 0.1673 | 4.5 % |
| police | 01_dark | 0.1799 | 0.1788 | 0.169 | 0.167 | 0.1752 | 0.1743 | 4.9 % |
| police | 02_rest | 0.1430 | 0.1617 | 0.194 | 0.176 | 0.1059 | 0.1418 | 17.0 % |
| police | 03_street | 0.1474 | 0.1506 | 0.155 | 0.150 | 0.1396 | 0.1466 | 6.7 % |
| police | 04_block | 0.1462 | 0.1447 | 0.200 | 0.201 | 0.1261 | 0.1229 | 8.3 % |
| police | 05_skyline | 0.1404 | 0.1433 | 0.159 | 0.156 | 0.1220 | 0.1289 | 6.5 % |
| power_station | 01_dark | 0.2275 | 0.2198 | 0.123 | 0.127 | 0.2533 | 0.2414 | 10.6 % |
| power_station | 02_rest | 0.1558 | 0.1765 | 0.177 | 0.149 | 0.1187 | 0.1595 | 20.0 % |
| power_station | 03_street | 0.1889 | 0.1727 | 0.119 | 0.136 | 0.2128 | 0.1706 | 21.3 % |
| power_station | 04_block | 0.1752 | 0.1512 | 0.189 | 0.251 | 0.1683 | 0.1226 | 21.6 % |
| power_station | 05_skyline | 0.1747 | 0.1477 | 0.145 | 0.192 | 0.1809 | 0.1183 | 19.2 % |
| residential | 01_dark | 0.2080 | 0.2073 | 0.158 | 0.159 | 0.2331 | 0.2322 | 3.9 % |
| residential | 02_rest | 0.1473 | 0.1786 | 0.167 | 0.138 | 0.1176 | 0.1818 | 20.5 % |
| residential | 03_street | 0.1654 | 0.1697 | 0.138 | 0.136 | 0.1783 | 0.1889 | 10.3 % |
| residential | 04_block | 0.1750 | 0.1801 | 0.188 | 0.195 | 0.1823 | 0.1904 | 6.8 % |
| residential | 05_skyline | 0.1598 | 0.1636 | 0.154 | 0.154 | 0.1692 | 0.1768 | 7.2 % |
| school | 01_dark | 0.1898 | 0.1923 | 0.144 | 0.142 | 0.1990 | 0.2032 | 3.8 % |
| school | 02_rest | 0.1347 | 0.1616 | 0.177 | 0.140 | 0.0936 | 0.1503 | 19.9 % |
| school | 03_street | 0.1451 | 0.1391 | 0.129 | 0.142 | 0.1425 | 0.1257 | 10.4 % |
| school | 04_block | 0.1487 | 0.1522 | 0.146 | 0.144 | 0.1481 | 0.1567 | 5.2 % |
| school | 05_skyline | 0.1451 | 0.1482 | 0.120 | 0.118 | 0.1457 | 0.1536 | 6.5 % |
| substation | 01_dark | 0.2209 | 0.2130 | 0.108 | 0.114 | 0.2377 | 0.2259 | 10.9 % |
| substation | 02_rest | 0.1762 | 0.1861 | 0.116 | 0.109 | 0.1724 | 0.1837 | 14.1 % |
| substation | 03_street | 0.1848 | 0.1580 | 0.094 | 0.121 | 0.2139 | 0.1486 | 19.0 % |
| substation | 04_block | 0.1492 | 0.1309 | 0.119 | 0.170 | 0.1319 | 0.0929 | 20.8 % |
| substation | 05_skyline | 0.1538 | 0.1317 | 0.096 | 0.144 | 0.1546 | 0.0970 | 17.6 % |
| suburbs | 01_dark | 0.1698 | 0.1691 | 0.157 | 0.156 | 0.1962 | 0.1960 | 2.7 % |
| suburbs | 02_rest | 0.1098 | 0.1317 | 0.127 | 0.130 | 0.0620 | 0.1002 | 18.4 % |
| suburbs | 03_street | 0.1608 | 0.1679 | 0.105 | 0.102 | 0.1718 | 0.1862 | 13.3 % |
| suburbs | 04_block | 0.1425 | 0.1465 | 0.123 | 0.120 | 0.1346 | 0.1443 | 6.0 % |
| suburbs | 05_skyline | 0.1518 | 0.1563 | 0.115 | 0.115 | 0.1660 | 0.1748 | 7.1 % |
| warehouses | 01_dark | 0.2181 | 0.2113 | 0.118 | 0.121 | 0.2213 | 0.2120 | 10.1 % |
| warehouses | 02_rest | 0.1588 | 0.1758 | 0.100 | 0.106 | 0.1181 | 0.1502 | 17.8 % |
| warehouses | 03_street | 0.1726 | 0.1494 | 0.101 | 0.117 | 0.1779 | 0.1250 | 18.2 % |
| warehouses | 04_block | 0.1631 | 0.1437 | 0.116 | 0.177 | 0.1473 | 0.1032 | 21.4 % |
| warehouses | 05_skyline | 0.1643 | 0.1428 | 0.111 | 0.147 | 0.1570 | 0.1031 | 19.1 % |

| View | Pairs | Luminance delta | Saturation delta | Contrast delta | Changed share |
|---|---|---|---|---|---|
| 01_dark | 11 | -0.0031 | +0.0007 | -0.0040 | 5.8 % |
| 02_rest | 11 | +0.0213 | -0.0141 | +0.0403 | 18.1 % |
| 03_street | 11 | -0.0060 | +0.0073 | -0.0150 | 12.7 % |
| 04_block | 11 | -0.0059 | +0.0214 | -0.0125 | 11.7 % |
| 05_skyline | 11 | -0.0064 | +0.0155 | -0.0164 | 10.6 % |

District spread: the root-mean-square distance (0..1) between the 48 x 27 thumbnails of two districts' frames of one view, the mean over the 55 pairs of districts and the pair that is least apart.

| View | Baseline (5d30659) mean | least apart | Dressing hidden mean | least apart | Dressing shown mean | least apart |
|---|---|---|---|---|---|---|
| 01_dark | 0.0660 | 0.0247 (hospital, school) | 0.0725 | 0.0269 (hospital, school) | 0.0710 | 0.0328 (hospital, police) |
| 02_rest | 0.0967 | 0.0388 (park, residential) | 0.0744 | 0.0213 (park, residential) | 0.0691 | 0.0286 (park, residential) |
| 03_street | 0.0709 | 0.0263 (hospital, school) | 0.0715 | 0.0263 (hospital, school) | 0.0731 | 0.0357 (hospital, school) |
| 04_block | 0.0838 | 0.0560 (gas_station, warehouses) | 0.0828 | 0.0500 (gas_station, warehouses) | 0.0880 | 0.0518 (substation, warehouses) |
| 05_skyline | 0.0573 | 0.0406 (industrial, warehouses) | 0.0574 | 0.0403 (residential, warehouses) | 0.0662 | 0.0384 (industrial, warehouses) |
