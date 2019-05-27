# Dieses Gnuplot Script plottet die Daten in den Dateien "Diesel- und Elektrodaten.dat"
# Diese Datei heiﬂt "Multiplot.plt"
set terminal pngcairo size 1280,1024 font "Times New Roman,20"
set output 'diagramme/Vergleichsdiagramm.png'
set title "Energieverbrauch Diesel-/Elektromotor" 
set xlabel "Strecke [m]"
set ylabel "Energie [kJ]"
set grid
set key box t l
set xrange [0:10000]
set yrange [0:30000]
plot 'Dieseldaten.dat' w lines lw 3 t "Dieselantrieb" , 'Elektrodaten.dat' w lines lw 3 t "Elektroantrieb"
