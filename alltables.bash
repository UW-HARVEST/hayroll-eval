python ./generate_outcome_table.py ./aggregated_statistics_crust.json --name CRUST --output ./outcome_table_crust.tex
python ./generate_outcome_table.py ./aggregated_statistics_libmcs.json --name libmcs --output ./outcome_table_libmcs.tex
python ./generate_outcome_table.py ./aggregated_statistics_zlib.json --name zlib --output ./outcome_table_zlib.tex
python ./generate_failing_table.py ./aggregated_statistics_crust.json ./aggregated_statistics_libmcs.json ./aggregated_statistics_zlib.json --column-names CRUST libmcs zlib
python ./generate_performance_table.py ./aggregated_performance_crust.json ./aggregated_performance_libmcs.json ./aggregated_performance_zlib.json --column-names CRUST libmcs zlib
