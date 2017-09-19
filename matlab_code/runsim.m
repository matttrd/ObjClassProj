cd /home/ferrarom/Immagini/
clear all
load('init_data')
run('Toolbox/vlfeat/toolbox/vl_setup')
learning
save('output/training_data','stat','blob')