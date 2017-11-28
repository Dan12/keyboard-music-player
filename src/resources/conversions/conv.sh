mkdir chain1_wav
mkdir chain2_wav
mkdir chain3_wav
mkdir chain4_wav

cd chain1

for i in *.mp3;
	do name=`echo $i | cut -d'.' -f1`;
	echo $name;
	ffmpeg -i "$i" "../chain1_wav/${name}.wav";
done

cd ../chain2

for i in *.mp3;
	do name=`echo $i | cut -d'.' -f1`;
	echo $name;
	ffmpeg -i "$i" "../chain2_wav/${name}.wav";
done

cd ../chain3

for i in *.mp3;
	do name=`echo $i | cut -d'.' -f1`;
	echo $name;
	ffmpeg -i "$i" "../chain3_wav/${name}.wav";
done

cd ../chain4

for i in *.mp3;
	do name=`echo $i | cut -d'.' -f1`;
	echo $name;
	ffmpeg -i "$i" "../chain4_wav/${name}.wav";
done
