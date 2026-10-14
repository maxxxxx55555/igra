# Measured deltas of the density frames (Session 23)

Written by `python tools/qa_sim/density_measure.py a4acbb5 --write docs/DENSITY_MEASURED.md` from the pairs of `docs/stills/density` (the same run and the same code: `before` has the district's dressing node hidden, `after` shows it).
Luminance is Rec. 709 on 0..1, saturation the HSV S of the pixels brighter than 0.05, contrast the standard deviation of the luminance, over the frame without the parts the HUD still draws; changed share is the part of the pixels
whose luminance differs by 0.05 or more. 55 pairs.

| District | View | Luminance before | after | Saturation before | after | Contrast before | after | Changed share |
|---|---|---|---|---|---|---|---|---|
| gas_station | 01_dark | 0.1951 | 0.1954 | 0.146 | 0.146 | 0.2072 | 0.2086 | 4.1 % |
| gas_station | 02_rest | 0.1742 | 0.1855 | 0.118 | 0.133 | 0.1730 | 0.1888 | 12.9 % |
| gas_station | 03_street | 0.1568 | 0.1601 | 0.109 | 0.110 | 0.1730 | 0.1808 | 6.0 % |
| gas_station | 04_block | 0.1404 | 0.1482 | 0.112 | 0.110 | 0.1199 | 0.1395 | 12.2 % |
| gas_station | 05_skyline | 0.1497 | 0.1517 | 0.114 | 0.113 | 0.1553 | 0.1582 | 4.8 % |
| hospital | 01_dark | 0.1846 | 0.1844 | 0.167 | 0.168 | 0.1954 | 0.1956 | 2.5 % |
| hospital | 02_rest | 0.1419 | 0.1637 | 0.212 | 0.187 | 0.1175 | 0.1575 | 18.3 % |
| hospital | 03_street | 0.1517 | 0.1554 | 0.155 | 0.156 | 0.1507 | 0.1562 | 9.4 % |
| hospital | 04_block | 0.1525 | 0.1556 | 0.207 | 0.210 | 0.1403 | 0.1456 | 3.9 % |
| hospital | 05_skyline | 0.1369 | 0.1403 | 0.160 | 0.160 | 0.1311 | 0.1376 | 3.7 % |
| industrial | 01_dark | 0.2146 | 0.2082 | 0.138 | 0.142 | 0.2131 | 0.2062 | 9.5 % |
| industrial | 02_rest | 0.1571 | 0.1766 | 0.105 | 0.108 | 0.1143 | 0.1498 | 20.1 % |
| industrial | 03_street | 0.1718 | 0.1526 | 0.110 | 0.118 | 0.1700 | 0.1235 | 19.0 % |
| industrial | 04_block | 0.1856 | 0.1600 | 0.125 | 0.183 | 0.1804 | 0.1280 | 22.5 % |
| industrial | 05_skyline | 0.1622 | 0.1461 | 0.116 | 0.162 | 0.1497 | 0.1100 | 18.4 % |
| park | 01_dark | 0.2079 | 0.2040 | 0.138 | 0.139 | 0.2377 | 0.2325 | 3.4 % |
| park | 02_rest | 0.1433 | 0.1765 | 0.132 | 0.111 | 0.1132 | 0.1797 | 19.8 % |
| park | 03_street | 0.1511 | 0.1555 | 0.099 | 0.099 | 0.1639 | 0.1726 | 6.3 % |
| park | 04_block | 0.1478 | 0.1532 | 0.121 | 0.122 | 0.1526 | 0.1613 | 4.7 % |
| park | 05_skyline | 0.1480 | 0.1494 | 0.103 | 0.104 | 0.1649 | 0.1668 | 4.3 % |
| police | 01_dark | 0.1799 | 0.1773 | 0.167 | 0.168 | 0.1762 | 0.1726 | 5.3 % |
| police | 02_rest | 0.1432 | 0.1620 | 0.194 | 0.174 | 0.1063 | 0.1422 | 16.9 % |
| police | 03_street | 0.1478 | 0.1504 | 0.155 | 0.151 | 0.1396 | 0.1457 | 6.2 % |
| police | 04_block | 0.1423 | 0.1487 | 0.206 | 0.195 | 0.1177 | 0.1310 | 10.9 % |
| police | 05_skyline | 0.1409 | 0.1420 | 0.158 | 0.157 | 0.1233 | 0.1254 | 5.6 % |
| power_station | 01_dark | 0.2272 | 0.2220 | 0.122 | 0.126 | 0.2527 | 0.2447 | 9.6 % |
| power_station | 02_rest | 0.1559 | 0.1765 | 0.177 | 0.150 | 0.1187 | 0.1596 | 20.0 % |
| power_station | 03_street | 0.3034 | 0.3768 | 0.107 | 0.150 | 0.3037 | 0.3268 | 59.4 % |
| power_station | 04_block | 0.1756 | 0.1539 | 0.188 | 0.245 | 0.1693 | 0.1284 | 21.6 % |
| power_station | 05_skyline | 0.1738 | 0.1456 | 0.143 | 0.192 | 0.1788 | 0.1138 | 19.0 % |
| residential | 01_dark | 0.2080 | 0.2088 | 0.157 | 0.157 | 0.2335 | 0.2345 | 4.5 % |
| residential | 02_rest | 0.1472 | 0.1787 | 0.167 | 0.139 | 0.1176 | 0.1818 | 20.5 % |
| residential | 03_street | 0.1640 | 0.1686 | 0.139 | 0.137 | 0.1773 | 0.1877 | 8.7 % |
| residential | 04_block | 0.1745 | 0.1788 | 0.187 | 0.192 | 0.1815 | 0.1879 | 5.7 % |
| residential | 05_skyline | 0.1509 | 0.1621 | 0.161 | 0.159 | 0.1492 | 0.1752 | 13.1 % |
| school | 01_dark | 0.1884 | 0.1876 | 0.144 | 0.145 | 0.1976 | 0.1969 | 3.1 % |
| school | 02_rest | 0.1346 | 0.1615 | 0.177 | 0.139 | 0.0936 | 0.1504 | 19.9 % |
| school | 03_street | 0.1453 | 0.1499 | 0.127 | 0.126 | 0.1435 | 0.1534 | 6.3 % |
| school | 04_block | 0.1486 | 0.1514 | 0.146 | 0.145 | 0.1483 | 0.1545 | 4.5 % |
| school | 05_skyline | 0.1360 | 0.1464 | 0.131 | 0.118 | 0.1235 | 0.1489 | 13.4 % |
| substation | 01_dark | 0.2217 | 0.2152 | 0.107 | 0.111 | 0.2389 | 0.2294 | 10.1 % |
| substation | 02_rest | 0.1761 | 0.1859 | 0.116 | 0.109 | 0.1723 | 0.1835 | 14.0 % |
| substation | 03_street | 0.1816 | 0.1543 | 0.097 | 0.125 | 0.2042 | 0.1370 | 19.0 % |
| substation | 04_block | 0.1515 | 0.1326 | 0.117 | 0.167 | 0.1360 | 0.0954 | 21.0 % |
| substation | 05_skyline | 0.1530 | 0.1311 | 0.098 | 0.148 | 0.1553 | 0.0966 | 17.7 % |
| suburbs | 01_dark | 0.1698 | 0.1693 | 0.158 | 0.156 | 0.1962 | 0.1961 | 2.7 % |
| suburbs | 02_rest | 0.1097 | 0.1319 | 0.127 | 0.131 | 0.0619 | 0.0999 | 18.7 % |
| suburbs | 03_street | 0.1572 | 0.1606 | 0.104 | 0.102 | 0.1737 | 0.1824 | 7.4 % |
| suburbs | 04_block | 0.1427 | 0.1456 | 0.123 | 0.121 | 0.1350 | 0.1423 | 5.6 % |
| suburbs | 05_skyline | 0.1441 | 0.1578 | 0.113 | 0.111 | 0.1421 | 0.1726 | 14.0 % |
| warehouses | 01_dark | 0.2169 | 0.2116 | 0.119 | 0.122 | 0.2201 | 0.2125 | 9.8 % |
| warehouses | 02_rest | 0.1591 | 0.1760 | 0.101 | 0.106 | 0.1185 | 0.1506 | 17.8 % |
| warehouses | 03_street | 0.1729 | 0.1551 | 0.100 | 0.111 | 0.1784 | 0.1362 | 18.1 % |
| warehouses | 04_block | 0.1620 | 0.1413 | 0.116 | 0.176 | 0.1435 | 0.0988 | 21.7 % |
| warehouses | 05_skyline | 0.1582 | 0.1430 | 0.105 | 0.142 | 0.1397 | 0.1027 | 17.6 % |

| View | Pairs | Luminance delta | Saturation delta | Contrast delta | Changed share |
|---|---|---|---|---|---|
| 01_dark | 11 | -0.0028 | +0.0014 | -0.0035 | 5.9 % |
| 02_rest | 11 | +0.0211 | -0.0128 | +0.0397 | 18.1 % |
| 03_street | 11 | +0.0032 | +0.0076 | -0.0069 | 15.1 % |
| 04_block | 11 | -0.0049 | +0.0198 | -0.0102 | 12.2 % |
| 05_skyline | 11 | -0.0035 | +0.0149 | -0.0096 | 12.0 % |

District spread: the root-mean-square distance (0..1) between the 48 x 27 thumbnails of two districts' frames of one view, the mean over the 55 pairs of districts and the pair that is least apart.

| View | Baseline (5d30659) mean | least apart | Dressing hidden mean | least apart | Dressing shown mean | least apart |
|---|---|---|---|---|---|---|
| 01_dark | 0.0660 | 0.0247 (hospital, school) | 0.0666 | 0.0230 (hospital, school) | 0.0666 | 0.0303 (police, school) |
| 02_rest | 0.0967 | 0.0388 (park, residential) | 0.0653 | 0.0212 (park, residential) | 0.0602 | 0.0286 (park, residential) |
| 03_street | 0.0709 | 0.0263 (hospital, school) | 0.1000 | 0.0298 (gas_station, warehouses) | 0.1182 | 0.0342 (park, school) |
| 04_block | 0.0838 | 0.0560 (gas_station, warehouses) | 0.0831 | 0.0560 (gas_station, warehouses) | 0.0870 | 0.0508 (substation, warehouses) |
| 05_skyline | 0.0573 | 0.0406 (industrial, warehouses) | 0.0553 | 0.0360 (police, school) | 0.0653 | 0.0362 (industrial, warehouses) |
