#!/bin/sh
set -e

# Go the sources directory to run commands
SOURCE="${BASH_SOURCE[0]}"
DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
cd $DIR
echo $(pwd)

rm -rf ../fonts


echo "Generating Static fonts"
mkdir -p ../fonts
mkdir -p ../fonts/ttf
mkdir -p ../fonts/variable
# fontmake -m CinzelDecorative.designspace -i -o ttf --output-dir ../fonts/ttf/
fontmake -m Cinzel.designspace -i -o ttf --output-dir ../fonts/ttf/

echo "Generating VFs"
fontmake -m Cinzel.designspace -o variable --output-path ../fonts/variable/Cinzel[wght].ttf
# fontmake -m CinzelDecorative.designspace -o variable --output-path ../fonts/variable/CinzelDecorative[wght].ttf

rm -rf master_ufo/ instance_ufo/ instance_ufos/

echo "Generate Vollkorn SC VFs"
python3 -m opentype_feature_freezer.cli -S -U Decorative -f ss01 -f ss02 ../fonts/variable/Cinzel\[wght\].ttf ../fonts/variable/CinzelDecorative\[wght\].ttf
pyftsubset  --glyph-names --layout-features="*" --name-IDs="*" --unicodes="*" --output-file=../fonts/variable/CinzelDecorative\[wght\].subset.ttf ../fonts/variable/CinzelDecorative\[wght\].ttf
mv ../fonts/variable/CinzelDecorative\[wght\].subset.ttf ../fonts/variable/CinzelDecorative\[wght\].ttf


echo "Post processing"
ttfs=$(ls ../fonts/ttf/*.ttf)
for ttf in $ttfs
do
	gftools fix-dsig -f $ttf;
	# python -m ttfautohint $ttf "$ttf.fix";
	# mv "$ttf.fix" $ttf;
done

vfs=$(ls ../fonts/variable/*.ttf)
echo vfs
echo "Post processing VFs"
for vf in $vfs
do
	gftools fix-dsig -f $vf;
	# ./ttfautohint-vf --stem-width-mode nnn $vf "$vf.fix";
	# mv "$vf.fix" $vf;
done

echo "Fixing VF Meta"
for vf in $vfs
do
	gftools fix-vf-meta $vf;
done

echo "Dropping MVAR"
for vf in $vfs
do
	mv "$vf.fix" $vf;
	ttx -f -x "MVAR" $vf; # Drop MVAR. Table has issue in DW
	rtrip=$(basename -s .ttf $vf)
	new_file=../fonts/variable/$rtrip.ttx;
	rm $vf;
	ttx $new_file
	rm $new_file
done

echo "Fixing Hinting"
for vf in $vfs
do
	gftools fix-nonhinting $vf $vf;
	if [ -f "$vf.fix" ]; then mv "$vf.fix" $vf; fi
done

for ttf in $ttfs
do
	gftools fix-nonhinting $ttf $ttf;
	if [ -f "$ttf.fix" ]; then mv "$ttf.fix" $ttf; fi
done

rm -f ../fonts/variable/*.ttx
rm -f ../fonts/ttf/*.ttx
rm -f ../fonts/variable/*gasp.ttf
rm -f ../fonts/ttf/*gasp.ttf

echo "Done"
