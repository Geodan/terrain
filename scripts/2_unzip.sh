for f in $(find ./tiles -name '*.terrain'); do
   echo ${f}
   mv ${f} ${f}.gz
   gunzip -f -S terrain ${f}.gz
done