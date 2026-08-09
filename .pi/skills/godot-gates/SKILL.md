When: после любых правок кода/сцен/ресурсов.
1. Запусти 4 гейта (compile_gate, signal_arity_check, i18n_check, asset_check) headless.
2. Требуй: COMPILE_GATE bad=0, [sig] DONE fails=0, [i18n] fails=0.
3. Красные — чини сам и повторяй. DONE говори только при зелёных.