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
fontmake -m Cinzel.designspace -i -o ttf --output-dir ../fonts/ttf/

echo "Generating VFs"
fontmake -m Cinzel.designspace -o variable --output-path ../fonts/variable/Cinzel[wght].ttf

rm -rf master_ufo/ instance_ufo/ instance_ufos/

echo "Generate CinzelDecorative VFs"
python3 -m opentype_feature_freezer.cli -f ss01 ../fonts/variable/Cinzel\[wght\].ttf ../fonts/variable/CinzelDecorative\[wght\].ttf.temp
python3 -m opentype_feature_freezer.cli -S -U Decorative -f ss02 ../fonts/variable/CinzelDecorative\[wght\].ttf.temp ../fonts/variable/CinzelDecorative\[wght\].ttf
rm ../fonts/variable/CinzelDecorative\[wght\].ttf.temp
pyftsubset  --glyph-names --notdef-glyph --notdef-outline --recommended-glyphs --layout-features-="ss01,ss02" --layout-features+="locl,dlig" --name-IDs="*" --unicodes="*" --output-file=../fonts/variable/CinzelDecorative\[wght\].subset.ttf ../fonts/variable/CinzelDecorative\[wght\].ttf
mv ../fonts/variable/CinzelDecorative\[wght\].subset.ttf ../fonts/variable/CinzelDecorative\[wght\].ttf

echo "Generate CinzelDecorative static fonts"
ttfs=$(ls ../fonts/ttf/*.ttf | grep -v "Decorative-")
for ttf in $ttfs
do
	dttf=$(echo $ttf | sed 's/-/Decorative-/');
	subsetdttf=$(basename -s .ttf $dttf).ttf
	python3 -m opentype_feature_freezer.cli -f ss01 $ttf $dttf.temp;
	python3 -m opentype_feature_freezer.cli -S -U Decorative -f ss02 $dttf.temp $dttf;
	rm $dttf.temp
	pyftsubset --glyph-names --notdef-glyph --notdef-outline --recommended-glyphs --layout-features-="ss01,ss02" --layout-features+="locl,dlig" --name-IDs="*" --unicodes="*" --output-file=$subsetdttf $dttf;
	mv $subsetdttf $dttf;
done

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
