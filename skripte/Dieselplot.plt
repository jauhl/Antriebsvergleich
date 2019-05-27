# Dieses Gnuplot Script plottet die Daten aus der Datei "Dieseldaten.dat"
# Diese Datei heiﬂt "Dieselplot.plt"
plot 'Dieseldaten.dat'
ymax = GPVAL_DATA_Y_MAX
set terminal pngcairo size 1280,1024 font "Times New Roman,20"
set output 'diagramme/Dieseldiagramm.png'
set title "Energieverbrauch Dieselmotor"
set xlabel "Strecke [m]"
set ylabel "Energie [kJ]"
set grid
set key t l
set xrange [0:10000]
set yrange [0:ymax+100]
plot 'Dieseldaten.dat' w lines lw 3 t "Dieselantrieb"




