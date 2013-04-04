if [ -f ~/.bashrc ]
then
source ~/.bashrc
fi
echo -e Running on $HOSTNAME
time cat in.txt
echo -e Return codes: ${PIPESTATUS[*]}
