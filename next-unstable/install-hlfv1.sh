ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.17.0
docker tag hyperledger/composer-playground:0.17.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� E�OZ �<KlIv���Ճ$Nf�1�@��36?����h��G-�")J��x5��"�R�����׋�6�`� �� 9g����!�CA�S�"�$�5����&EY�-���lU�z�ի��O�b�؊�F�4l15iرWW�Þ����8�t:I~!��%�'�����$�qRϧ�L�?'��-��HB�8�t��'Ý��-�زUCϡk�5���u����qB�NX9x&鎤���ӥ����Q�I��MliX�`+6j�5˱J�"��r|9�#�]�t��뀶*�-��� ����.i�n��y�ܛ��7������F��6�Ν��L&u��C�ퟏ��S`��s�dFy�����8��>jwρ���������|"%�����$�������q��걖dw9�p-���u$+�GQ-�k��i^�Z����nJ�⏟�э0�z�}�b{�!)�}��b���H�E��!U�	�4��n��>b�AV�����M-3�����}]Դ"�_��b����B<��@�(�y~n�R���-"b����I!r���T�FIW��{�!�J�,W�U�3N
m��d;�y����j���u��2myr�S�������

��������
o =��8��t�]>C1Pؘ�jI�'�̵U .L��ԅ�7� G��B��!�Eڄ�3"�U_�FPj4K��d�>���Ym̴�ɤ�Ng��{�*�8�0C�jXt���cG���u�p�>�Z����
TG
^Nޜa�!�ߘ� C׆T �z���I�`a��oEC�2��.����N�wŀǡ�A1���X	�4,��Xò��]U�"ä��
s��^�N�]ET�8�I��'�0!��y��:�32m�Gw ��&؊��\�0޺�i7�9�F�ea����1�e������5�����-ɜb�x>��2#����ܖ ���� L��X ���E��������E����9�8���d"A�x!�H�<���g2s�����">Ěa����̖-�tPR����,C�%9$�k��b9�kY8H~kȽ�F@s����Uh�k͕��5a�[<����5�������g�K4W�A��*����N��Uެ�<g�^�;�T����[���n��j�C>��q�&;���f���d�����-M6�d�r�߭��h�5˕��v�d�'�f�Χ�u�d)��cC��§�HZh�k?x�d�\�F*���ѣGhi&��%�Ǐ��"��剬�P2q	�n���0��p�f��'}�LN�@' <���D��cm���j �I-�<~�N��d3��)�����ۆ~.4��_���?��� �?��0���?	?s��)�\���p��+C�i�		H<��<�V03*�ik)�34b��$aV 9�q\�q��9�v��Zd�#lZ����Ŵ��Ю���O��	;@�pЁ�-V�Z��:�i�b1h麭�l�b3)���(�ݟQB��t�,0���OSeN� �`6]�q�t��}�Rlh{�X
q���@�J�>��ͥ{�������m���D$Kئw5E"䧭jE���H��xP �"6��`]Vq '�$�~��f���R�����&�э�`~���T˨�B�{�vx�oVy���]�'�����2_���e���a����K�:5��u1en�ow�a���!�al�JO����#8�����,�2ir������)s��ˉ�?Z��,�,)_��f�B:3e�||~�w1���ު�����f)�f���U�ia�Զ�:�G�T4��wÅ�c�;��*3�j���i����L<������r���#.�U��4���?��3B2)�����|�/��y�_ᭀS�f�����9'��|�1e��o��:j��� lY�u���;ޅ�^O�;ʑ#��m[���7�Sn��نG�%��S��E���ѹ��c�6�U�ܨ"��o;�ǰX���`$�ºԂl��l�4	��^H=S���(;�~�q5ɲ�hu\��f��wI�--�H�Aqr<�����ɓ���Hk��^�W+WW7W�1�	�̤/�!���:xG����^e�X�跰@�m.,�]��p��qf��ο7<b �&�W���E���!�W��yr-̉�����.M#��_ӽ�ݩ��uq��Qj쭖�V��ѡ^L�|�$L^j�.k�`oړ��Jb���&!P�M�L#��9�vqM�"ྤ�xgt�
`�N��h3s�Q��ߜ� }�|��y����^�T�,B�]��̻pck�!ah�M�gȻlB��o��Ak�[ޱ�k�9��$tD��35�J��5λƎXF&,�Q���Q�,�������@<,Q`� �e�8���ˤ�^031��S��z[�8��u�ٻ�����?0���(��+l6J{��Ae�Vج���jbs}�=ی���4]ݙ�D �g�>a7Қz�J��-zWv�tW٫�l�ɵ|�cn��7����[ZΜ��­���ƽ�Ͽ�)�or��]Dy��om��m/�#D_>IXD5�{Cȑ:=�r�_J"�G�KA��5I�K��8��>�G���C�O�'K/�K����t���K�4\���fv}ӊ8/o�����y��8������d�p��s����G�������|<��{���@�$$S�|��B
,�sh������
�e�Q$B�h�:50�%�-�`_+>��c�^#eB��V!���W��"��x΅�G�;@������nc�[0�t-���k28��!j����=�`��*��2a_��$��)�C�2��<e�`�2����=.oD�Kȿa����ֱ��_LBȫ�M�}�i}����	�M�#���6�&�؇�F��o- �a9�ۛ�2�qp�)}�~b��
��`"7��&���ʔ��Z_Z<���R�-L�������f���¾��
*�^|���t�4�R�tTl{o��UM��@�-L;�`l{H���P�u���������
h��&騲UC�Mv�k6aF*;���� C�"�rm�x�Tj�����r�� 0��%�`�G����,F[e�gs~u�I,"O����ɜ��e�͏�1�m�ʢ.yab	�e����S��?0�V.�E�+��x`0v�\�Q P�YT-�=勸����t��y�c�}"��#c�����3|������
2世bjp-��Y�	�N�l��`�*����P� ��R%_jp�I�<����$��'��O��l����g��M����N�t�kX�.ǔ�]6M̂f0�M�j�VO��Am~���'[�M�Z�AxPM�m����Q5|��J�Ko���^�p�Ro�;,#�?:��C��g[���;acv*�� ��P&�z��Th�7��8=�PI�Ĉ�$ ϒg��cݖX7â�&F=-#H��~�	��6,S����@�U���lR�g5*�b���;>��S�CI���#y��	����-#Lw��R�@
S`��@@mQQ,l�8`	��'F��%t�����:�_�g�$��Ӂj�ॅA���)�1#�"})��G"ؓط�#L�,��7�xvDh�e� ��ZUvb�#�8&"�4@�PÌ��4P{no@kb�C;rO��4�y��x��آ/�aJ6?t@�LV���t[��p}rͰ�.��zl���R�,���]�G({��˨�rW�ٗ���3��s���j��98�Q`�E�5���`4|H&�f����;H�І'�b'� �e�� k�M�� k�
N#�0V�@:8,;��]=ܶ1*�r��S7���dDk�M�B&J_r�e�Ya�)Qs��Xo>
L�0��xJG%1���{�'x�!S���o=�1�)��s�
�8v1�@
΋	�"�:kE��&;8�3N�E�����߱��Sh���<����R�����B
���r{����^y��?��/~���N���N��r2)d��2/�ɬ�n���r6�n��BR�H8��d:�meIYJfS�,��,���r*��w����M#������a�]�~��eB�\Y��.O�Яs��?W��R�'�&�|q��1�p�{��N���B�r�[!n��wa��	`�s7�����2 -�A�&w�0^����l���g��������h����Lħ�?����_L��WPb�����2��?�׭��-�o����_k�������|�;����B�s_����ܐ{t��w/�����cwz�GU>��L'�
��R2�d��'�d��$�,N�����TR�
)�ZVxAH��嬠$�\E�J�{�n������|����\��1�o~����c�� ��8��x�?��lL����Џ?�e`���0��z���?��pߪl�B��A��B���o�$��EHɗ��UT(5���rAl�h-W)���BAĽ��/��N�^����./o�t���u����������t�t�7k�zQ��U�v�+�w�;��Z�wg��Ԭ !��.򕍺�jK�ʽ���,ݯ��-?�T��U�\z8�v������Q�a%/���J����W�R^[u䵁v�W=l5Kr%oPqPi�
%��(��~|P=���_OU�JP7duu����W�#�n�S�ɋ�MQ�iV�~��\�����a/;l��n���_i�z��7a�NC��m���,T+���j�l�y�<���I������mwW�:�F��֡0E�4���n�f��K����a�h?^�e�(��b�#������w����f�h��0�S�=������Ô�o>�5��ȩv��ES�5숫�w���7Z\�hu�z��?���v S]�ڮ���E�f#^�뱼s�Y�U�e2�]�OE�]����_�S�&���R>v$�D���d�ܩw�$G{��K�u�)�M����=���w�d��^~`������$�/t��@C�@�˝��ڏi��N~W*u*7�.k������u�c&�"w�6By�&o������m�!�����J77΁�Q6q���ە�{+�Q�(U���%�'�Z��&�0���Xu7���͡˯��(h��q���=�"0�V
;;�A�Hl0��4�nkM끾����`u_�fmr��mj~��{��5�Ѯ�<Xk����?���Gq,=�F�Q�;;;bv5��h3)
����+��06�`l0p���m�7�`�jr��HQns��\�_D��'	�*(������=]�i��2v�9��}�s��A�w����w�C�ˆ}��(���u}�b�:���{O��CGU'VG��0$�L������c�9b��KБΈ�SX���Ǳy��F�I0��{�)�"����+8����q7�c���Ê�rm�j�8��ҙ�7��z5sDD$?�̖!��Y}lv�I����S�X=��S�E̗U��Be�l�}\؉~\[W\����'_�XKڶ��r�Z
�xe�1�W=H���������֚b%��V��8�M����:��h�`�B**Uܲ�
3?�֡�8�Ehs���aM#!N��s񲵧	�.g�"�K����vܡ7ܠ�K�N���T�w�ye.,,A��Z�P��T��8��6��b��@�`���ЫZ�2�� ��y���|v���#l�Ң��!U�OZ�lwv�L���7p��q�����>�J*�޳C�Ğ煞r\=� ��aۇ����t�?ݡ�o���)y�mY�^�#*T�4��h7�T�9mV����!�te&XBp`J$^i[x�Ot��B��"�[������%�P�9�9��a�ۂ��wh8����cġcCm�5�ԙ���*4�"S�����m>��z�O;��2B�9���)f�O��u�Q�d��n��&4�=��ƞ�M7er*<��N��t2~[�˃%��������>{��Ľݨ����{�G���+N�O�on:\e8|ks~p�����:x�W�������y������_z�?����W���E�����
��]�n��������ng������q#����¿~[��oO�'��Q*��T6�nc��7#�&k�T�juɁ�\�|���1��3�1�s��~�ĕkbᅘH��sA�Q��!x�z�j>g.蚺�X�o�+��2pWa�Gn$�{�P�D��c��s,$�6p(,��hX�U��#�*�&9R.�[iM6qsS�SDmLa��U��n����!nj�N��h�Ǚ����"����;s�C]�i\�L�*�_�e�wd�ɡ9c��	�c�g��z�5��L�%���.x_X��la?X��L��\�HQ�%Η���^E�MF��L�I���*ó0A�ݍ�]�F�a{:� ��v)|�m�vI��v�@�+vc��C���Ґ��C|���YݔF2^r$e��V;���?�ӣ��K��}�ZO.IR{�)�z](���������[a�c���ȕ=�9
d~���:�*��)|o����ʏw�d~8&]�O���H��;���~��Е�1���w���mN֚���[Ƚ��G�(�J3��֤Yo�=14�j��k����RqlZ{��ʘ�!�Uw�~ܚ�i�`����df��K}�!��RU!�'������BY�ʜ�0q����XN��9�ӭB�}��K~����o]���v�t��C(�^J�e�"T�?�Ҥ!�X��-7]��q�96ڃ� ��F�X̓⩵�+Bu�j���^��7檁$P���vq$���0������N��������m Q��T[̺�V����\�����$�Xdnɶrԏ�C0�_�C0�`�����u�c�`�J��1�@����3Lkw��(��Do
P��M̩@�/.d<-o��.���/Ě0��SK�������P�&��z@��p�D���Q�	(T��3�X�Ֆ�}l�H+�Ś/oJU�(�\t��+hl�Jոü��¢�z��Y��eB��k�tL�o0�.�m2�)�OP�E�z��0٠]��X���5�c�%�����B��';��wLZo��Pg:�R�V��C����L�~]��\��.BO����`�����4�_C��hіF��j�8,�:���o�_&���,\����7�/�/�E4�S~������/^A�����o����9���:_�R����9z;��Я�d
�cM������=q6��Y����w�7U+L��b&������D�C7�y��?@���ފ���h��J�O>�W�w��N�K�77�sZ�T 
��߾m�[�H&��+�� �g���dI�S^��_��?$����4���Z�;����!0�N�������O����OoJoJ��g~=�=���=p��㪭����߅dG�d���Gz??���W�y��y�=�3�G��׵j��M�� ���S��O��?>r��z��I��R���Zewt!@� ��?{�'/���T��'u,��y ����3������i S�w,�]}�-F �	����3�� �?!��X�M��|�ps�!�i#-������%����RH� i m�]�6�����=�?p���@��/�����l�����Y��SAN���y0�r��a��1��4 2�A���@Ϻf�\�?����i S�MB� [ ����_.��.�?
�?����U �#����	���
@�-PmT�zN���{�A.����!S�g%G������l����?3����l����3����`���"������꿱�����?3 ����_�C.�����)!��(���]����8J�ۣQw<k�ae�u���88�x�M[�g܅�g�0I�9�X��Oy����� �?���fK�l��5�w��b���͂Y��dl@�|��O]r�a0o���**i�E�h�G�����n(ܰ�$�Ն2�*���^���e�����m�Hg��;�qxS"[����VL��W��Df�؟a��b�`�2���Zà�0���[�wqSY�9C�?���2���L�� y����e�<�?���2���W|s��Y/y����Ç���+������Y�0S�bL;�ʌUߟ���*���ӏ��&tƍ��0�S�Y�[�2�"]cJ �5t�����`��f���*攖5�=�-�B�v�8,G�9��X\��:Z�b����E��q0��2�����Y}�����X��2���_ ��������0;�B���#`���������_�V�5T?ZU�?�Z^���S�'��*���n�"�Vؾ�,�1{G����m��hK��[�F�0����n=��sӲ;��=��2�n�b׋��
ao ��}�ds�;m�`��.��5X`�f��rXۮ��P�<�T�Z�]/�O���yfp����p�L����
�9�U�B�cY�]Mڝg���q�D �ѷ��/V�g����\�Ag�O:h�
���j�\�D����h�"�j�n�S����-;��ʑ�AR��+�a�b�Ei����x���mq�%ɸሰըn-��~��y�~����R�G��`��\#��l��o����\�?q���/� �E^s�������g�W�H��A���!-���_��o: ����_���`��L�?yQ����R�`�����������(rQ���O	i�?��%_ȅ��g�?� ���������������?��Kn����y����C���y�r������?��_��/`����<�?� ��e���oN �?�H�����1P�7��������?���7���AL����g��(|��/	�?d���8D� ��?s���!{��!Y�?���������K	�������w������R�� �?����C�����_@�����_� 7$3 ����_.�� �Y!O��`�##�������
��<�����#/�y�:�#��厬���mR���p�Ǣ,O�n�ik�L;�c��C9 ��/���&\V��n�7g5��o9%���r��h�d�Tt:�)Lw�$E�y�wv/l�3,�Ne[�ȸ��tgDKp�C�=J�@�'J�@�i�L�:8t�6)ia�h��l�h4�"9�����hqX	��L����qK��T��\�\$ ��%5GNi��k�d�������p�b��;#��g����
���8d� ��e�\�?q��/��!%��Aq�ԑ�O�G��T �?�����#���?���?P2K ����_.���̐+��!SG.�?�����#���?�\�B�!8�!{�7vwa4_���g��_����c�e�G��r��8�S��Q�GZ�E�-w��6��M�6B���e�%ǃ-
�<�qm�t�2�H��������c��������7[R�`���	�����/0
���n)�
N~9��q,TY��dl@�|��Sz���v��_P{�#�{Q-d�i�a��j�޸��"�8l1�t��+��]�T��Eg���U쫋}i��Ǔ	$�	).|̲��f ��r�G�vS���(�f�ԏ���r.˻&<Ң�߻���?�!�������h&}�E�?��!��d�����e�l`֟�KD�����!���\O��b7E�-`�/�q���LW�QEE�^i��A�-���Թ�lKt�X�x����#��I@�h��cʮ�Fi�Sg�5V_-d7j����(�UjN��b7�'����p���"����A �����c�qV��G��@.����� �@����_`��L���y�����f��|�V�Շ΂4g��WB��Ȍ�Kxv���g��nj ~H�����1�<�8�õ5�hiYZ��EQ��P�w��e;�a���*r�O44.aΨ_��I�ݕ1�b�H��=a�k�"��*R��e���8v���̃��ZL\�nt{u�R-֮2q2&��֮�����[s�����+V���j" �� �gϨ���~k���$��$��`:뙪�nC��t��w}� ���=jH������klx^]�ݰ�+�6Ox/ͩ}1YF=�$��:�O�%����u���f�;�h��5�����������$��K��r��%�F�dn�^����퐮x^f��J�4/��w�v1Zf"gQD¾;e��wT�ٙ���g�؝�6AM�_0~��GA��,���/
��܃���"ſ��U_P��;���?
`�����_���@��Y�&`#:JX�'p*�I�v���_1\��a�D�<~�Htb�`Ȁ$��+/P���y���?������������J$f�	�S��N�2I�F�D��o��H'V��ٷ����ܢ�a����:<����������O�������UWP����9��H����̫�_�@�Q�H���6Ń���Ky�&!�""��L����4��l�FM	i@q!1��$xD�`?�:����/�~��k�Y*j����g�2�1ŏw�Q���C�9�l��Ә��R����.W��Z�H��Z��[���'���"=�a�WMA��o�C�����_���u�����o�����{�?�w����
~���w�&���b)��(���#�W��?������}ժP�!(����a`�#��$�`���G2����{���_��?����H�Z�o`�~�2������?����:���W�^|E@�A�+��U��u��(���ǡL�A��;��x5��aH��B���sY��s�נ�	{S�w�eG������zQ�3�.�(1�^,�*eg�^Ǽ~�[��,�ƀl�����8�gJ�{��ɴ\�}���M<f��yxQ|S��<5!�Y�C�eUdJ�s�s+��_��:0�����`>R��8�^�(��:��t���ӫ�?̊Ĕ�S-��_�|4+[H��H-~�(��蜥U��N��f��̾t��Ma��5���fY,����u��5!6����qHl�c��.{���Vj��=�~�o�]�x��RW��?�xu��)NTLj�~#>�9���R�����{Q��� S��r�J��{����`���SNs�=�q~�N֋t���/�[��Kڢ���ݼ�t�{i(���N�d.�Y�ew�lC�E�&�{�d]/#�a��7t����y�	Y�w�/v��I�&?*��߭ ��ߣ������:��,[C�������ϰ���?#�^���"H|u��4ɾ������������?X��zd5�qSR������b9x��]~u������/E��寃RC?i-1�_c:
iM���ᅥ6�,ӉJk�����=G'��k�����0o.��\�GS�s.�TFjJ�=MQ���d��g*$���{�EI=��I��4t�Q�=r�x61�9�g[S̳�����o�-m7��h��x8�1&�s��l�֐�3�۬O+g5+���H]S�U�]���vo��%�?�x�h��?\����Q�V;?8p�.	���.Jc�ݬ�I����۬9#;�F����?�SS������@�c�b��mCg��|pOhN�~�k�L2\{n9�r���l�l��:�8o��&P�����L�ೳL�1�\[��{��B-�^ ���Q���i8 $ *��׎�j��̃�/��DB���>' Ȩ��g���0�	?����������_9�����`-�Ǘ��>�>�'+9���X�L�6D��� �i�6�p �r!��k �����}���<���u �s!�x�^��a��*�9P'��6|¢�3��7���Ƕ��F.�0&�w���g���m7�}�\�B�#�|S�A�؟�`υ ���\L�(�x�	�b/�Y,i���KID\��%5l_M�^��#-�젴6!V4�1e���V�^O�L��j��	f!��ˉ����d��=c4c]����>�i+Hi*��<�R~��A-�?���Q��/�}�%�����_-��e�L��  1u��p�_p���p�������Z�ă�O�?�!�[$�b��p������:�?E>���	����F�!�pl���S8��B�Ft�GMR	E0,xD�x<!���4����wS����?"~��7��nW2�YS�-B�{���R���l���b�5y������b�Z��t�v s�ˈ^�˼&F��y`3g��Lw���,�������#2��f�=��-���U"��ܔa��[����VG����}�����Q����Q���?�6��w��Q��W����#�dN�}�)ۍ�����n��ڼ_l���m�ڟō���?'Y쇇�Һ4�^�!w��ϖ�� Oq�:l=KNĩ�o��� �;[�L'��*n�[���Q䦙�8e��v=�O���V���� �[ux�G���w|s�ԡ�������������?�U����j�����?���������{�'u�%{�]ǃb~�lp���v��{lw�Z�/�*�	��@�-3��M��-6N�l��a��Cm�	3\#h,n�[o�kE�C�H���cq��=#�3c����e/lS���󬛱�B�='�
S�K�ul�e���ی��['���n[*M��wa'eJ[���Ĺhb?m葁�5���X�q$�B���w�D��2��1kܣ��¢]�x�,��2�u�;��Vh��3I��qH��X���[��'?BC�.|C�I�=�)b-t�\'�l��7bA$�l���Fr�R�f��0�v�߷W���� ���@����5�����������$�B��W���@��0ߵ�����W��$A��Wb���5���w�+�_� �_a�+�������W��p��D��x�)���v�W�'I��*��Ê�:Q�������$@�?��C�?��������?X�RS��������:��?�x�u������0�	����������G�!�#�����	��Q ��������א�?��$�`���4��u��������/H���������4�c^����WD���!Y&��y���� :�!�����y�O� �o� �$c^Hh.!6H`��gQ��h���H����^xX\��LVS�!1f���(�ZVIO�툾��I�&���ah���&S����B��|��>~�j��Q��zEI��lU��=�T����;�X\t��+)k4�uI���d���ή�S�6�x+ux����<�Q�@��>�����������QP�'�����	����j	*����������?�����j����U��/���j����c�*4��aJ1Q���D��<ΧTD1r4��x�4Dp�)���?��LC���_��/��x������m�-�9鶩���г�G�'E�?�����g;i7��Mm%,V\�h�#�v����>f�����lNL��&�Tp����l솝�|����t��#
��8���馹lA���������@���K���������S��GA�����i� �����W�x,T�?���� ��_�P���r�j���\����$�A�a3Du����W��̫��?"��P�T�����0�	0��?����P��0��? ��_1�`7DE�����_-��a_�?�DB����E��<����``�#~���������O�D:�r�S�4��r�g�������������������ٔ����~���}��pe�'=\&^j�K3ۆ���^�C��6��]����F(W��(�.�YI��ů��Ǧto"��յ�Z��O����ODS,���r�	!��Xwk?��A���_l<����j��/h��h�3R���A	�s�w,�NZy��L��I%YMU�U|(�Ğs���p��$����}a��KlUĺ �}F�G�heM���7j���0�u��~X^���� ����Z�?� ���P3��)Q����4��f��� �?��'�����C�WU���r�ߎ/�����B���WF��_������Q��������[�$?�[����j�㦤��17˕�r�ҁ��E�b���{��)�F�I����Dg������\]��!�S{.���ENkt��LR�hվ���eB�'���rGQ��Q�x:�R��yH�'�%�kLG!�)�]=��Ԧ�e:Qi�u�tt���w{m�����ͥ���h*{�e����3MQ������ǈ�������E�EI=��I��4t�Q�=r�x61�9�g[S̳�����o�-m7��h��x8�1&�s��l�֐�3�۬O+g5+���H]S�U���[���۽ղ�h>Yu۔ĔWĹ(�r����r�0eCԥ����K�����Xm7�a�A����6k����Ap0����u�u��g����>������d�Й$4\��ӵ��Z:�מ[���73=2����9�۹�	�4�0��#S���,�w�-����F-�?�A�'�DB�Er.��.����_;����S������P+��Ӑ࢔!�g��ᙐ���0�:�C.��(�X*`�����"6b(�
�����p�?�$����ť���L���v�b�"/���"�6+QhP�R����6U������������c�I��Ƒ�����I&�}��v�貭ؖI��~��$���d��}� �"uXr�#�=��B�PU��Q��Ն���^��lZ����0�yxrn]}�i��Vs822��m�{PӪճ�V�5e��'�����:U����7M�a����|����o7}�2=����=]z�����s����8��OM��������{��3�?���u�ko���� q���|i��?�:�j�qy~~��:�6]����d��ڇʠ��
�1����ƍw�4�51��'M�TnγɫA�=�3�k�z���f�O�G}�M��q4�Ol���}��<�&�������4=��?�]�}�������#q���p�k{����������������v�gk�=����|��,�?p��
[��1�:���+�����k�u+%��ѧ��M5U�j7�����Or��kI���m;���G� Dx����٥w �TU?��ei���K k� ��_��l�츔xs☙㯦��J^�[�H��A�|�nR?90.;�j���UI�4�N
ǟJ5�M!�xG{U�r3�;���u��p����\�D���w�����w ޟ�'�e���vP�3R����@3MKG���������n�c�c寣Ƞ������t�v#{vl�V"������ʁQ��?�'ˇ:]��?��7��i�}�^�p�<���AbWu�}U�o>>>*k��~�~bD�|�˗ٱ}�<)i�K��`�ٝV2����ӣ�G��������H%>N���K�;��������um����B6���\����%� s<����!��)�Y�8)�:ic�Mڌ����� �V�S�DS�a�X]e���5fIiL�!���I(c?/�h�R��-;Jb�������A�>1��Q�4c ټ1L��?� >�!?8< �i�+Z �j��fI�l��?�m�팙�G��i	��&=���7-��Fg#0l\��>6�"D���cp�H������wc.F�AX����w�zP���g�;�u<4�>�3��b%�P���� �I�A{:�lr:�5Es@D�,4���f���Z���]��U��S(C\��6�h��'�21�t��:쭐FA���&�5�,:�1�r,�� �s�,o�m��E��I`��U)o/�$��Wm���,��&�!�~|��"o�MA0��*�x Nhf�7^5�ʠ�k�NP��#��2��	6���U�0��n��+O���՝�bt�0�b�bw��oq��qx�|{��d��͞e�}��5�]�`�2G�FK]	DH���X�#�]3}0�h����&�i#1(��D!ga�(�Jpġl���s��P�\�o*֣60���jd�!�e��ԣ֊���\<	|8���9��D�E)�@R(#�bR�8C
$�W�b��
$���Gu}*rƣ���D7�+��]1���Ԩ��D�S1]É�<��l�0�Mgr�X�� `�gB�Wz��D���R3TvC^u���'�鋾����jr,Wq|�W����D�a�d��%J*C$�a:d�:.����6H�
�����Lg(�I�nsH�:_����˽�q�@��.*��D��q�S�5�>�tC:��a+��|�F�I�Ϙ�h��t�����:��-��l�p�t����ɒ�A7ġ8��(��&0SU�v���#�<F��s�Ɖ�������b�kƧw����s���S�d&�JA~:�Nm��=J��,��闑� 8�����a���� �z83Kg� xB��B�;�v��y*���-v�1aF2�Z�Lۙ�uP*�땋J��yZ�O0GI,+ysI�N����ƧF	@,A:�k�M�	xz��]��67��"��$����-�I�*1��k`�����$�+���yŦ��ڣ�|��z�dv7YP��J����{��|>��
���.�О��4�N��{,[`)���¾"�ᡷ���xBb�KN�kSwG,@���w}�(n�9�̺�Ɗ����"[��_Rp�����f�Zk��v���yxR�P;�WY��.V�tk�R�ڮu:��8���4�ߩwNkݣfu9e]у����vn|m0�,;��A��ѩJ��ӪW����-]��Q�ߒ��́LL�
�U��$a����Sg��-%1 K��q�Z���%�9�QO��'�1�`�Ev��*��_CPd;��� ���SZ_�y��]��X�~|_i�k������2��*G�z�Ҭ����g��N/j�j�Yot�]C�)&	�B��JX�!��dT^�U�ּ��Პح +�Ij�j�rU���n��8�^4jݏ���)�nߓ���In4$C�TP�f� W@o��G��R3�Z��v��nM�����r�S�#PV�w��4�*Gղ�|��`u�W���f������Ċ91e��@6X�������
���1'��`Nf���\U3ُk��c�ݹ���v���r��?q�*3C�/�(�ɹj.�o�GPMy�|>���VD�U�h��1gܹDQU�g�h�q��	�娎�+%F�����b�$�����칚�Ɲ��Nl�����Tvn�7[�l�%	V AK��E���(��%{�v�"�{`�|��i}�F<��@jM��T$�H��P�$f���u�hw�.[n��	�2���tT�/����M�"2�a��\������ ?���n�Ӻ��L!5����f��?����?������v�g���]�ٮ�l��v�GR�/���no� �]��.�l�{�6��F-՜�k�n�ƺ�?�ta���d��������=�H��=�c��<i��f�a�eZo����P]�����ٹ�*U�0�)C�\�EP�����I�ѿ�E{����Z�n�J��4A;1��(*������s��E�y֮��L�u%����_�x����] l�aW��0SEvD���x��m��������#�Lb}D) ������kqV����ya�g���$�^����n�lI�I<�-߭�Fv^�>�Կ�ؗ���k:��#5&�	QtF�͵���o;��;d�:����s�������OO/����I�����Ч�@���k
��ghtl���W���?�Xk`SE�F����I�S��O��O&����c���/_��l�^�&�"�0eh�h�{�_��CY�#��ؐ�'�������}��e�@���@%�ǐ���t���up���J��:���]�)^�z�4ywF�́7x��F�eC����!�@�����b�5�'�&A�
�8��DZԲ�E����؂��!��Iv^���!I��o�M�_
�e'���/@��_��/G��V�q�'&0��d�ͿIl���$�d��#�7;]Py��W5XlF �c���i����5�l��2��a/9x���4��G$���à1������'Q����x�#Ӝ�"}�����$ ��r%��Jb�?C��#�n�(��d<�îA�fu�$@�&W��?�b�:�"��8y����I��ʿ&�]n��<'��!�e�?�,��B�������>���*��w3�5����/���S��-�����x�b���kH��W���C�h6���1��,H3@%�:|�H�<J��%� qCFP��ￓZ��A���g�����/mӈ|�����"��I-�Vd�Ĝ�xY6���t�3]�g�I�Mv�p�ޫ�+B�7�^���N��������ǿ9~��$�ߥY��e�j��a�( h1\�>r{�k��Wl���bŨ\GZZ�6~��((6��0��	�-�×?W"�x��K��礵WS}q��n���=�p/9g,tmd�5�c��N+��%�^��]ǍI���\���MKs4���=�9�+��WHR�i����Xc��H����-�ډ�hlq0��K͏��U�3�p[I� �/��*L��g���<�
mH-x��I<a
�
Ɗ�|q\���?����?��Q�T*Ki/�
�^?�v3�����+�ޮ��MgX&���4�d�I��vt��*P�G��\�¾�`ܕG����������)0F���詔���Y�u��O8�q�7.����8Z���5PziA>g���d%�����\�C��7�p�]�K�;0�
���<�%�c�����{�B1y,1�K�\_�Xfva
�W5��3["�u�=,;�rLȒ������vD�Sm��*`N�c�l��o����l����`��K)�/�$[��Ιd��F^N� �S��۴����EK�ԛ� �[�Mes����v��1����
�� G�^SM�I0L��2}�Nn�ʴ����o����������O2��m��1Ҧ�Ϗ�<��(}��?����@�R���GI?��w�36 `�o�M�u�xb����cS��
$Đ-AsZHߦ@A�b���a��T���o;�`���~K4�vyد�ݛN���^t�5p��ש�-�@$�	z�۲��[gl��+`'�҈�c�1vÔgLũ>Y�w+ͥG�q�ɹ�=$���g�y�w&x'+P�:�7�6>z韚����nD�KD7֛�<�����G)�M�~�������
O�B
�&����{�����t�5�#�j���E���@x���xo��/�c���|2�]W>p�i��
3��Sa�:�&m���*w�����O}��c���O�[��Qҽ�ߛ�7��-���?S�|�?�.�S�t��l6�����H�ҽ�ɉ�O�\y�o1R��}Ƨ�P�[�Џ̓0��vqE�
�UY�R5Em2��@?/hz�����i������]{����.���bhS��ߋ���KU\��CB[Ẅ�ѫ��(����7��� ״�*9�]�/.A���]�Xi��cykKH����D��;b������n0�(*!��<U@u�q�ĭd1c�rh�����gΎ�BE?�ϑ���
w����7jpǈ�O�����CAH�!��tu�og�D`W	O�ү��^=��t �
r>�V�uZ��pk�ȯKD���D1��9oQ�7؇ <y�Q��xP�k��c<p�ɯ�ߏ��ի���S�P����t�����"@��]��b[s�$n�E?�5y���	�L�*�{ޙ��^=����k}�Ҝ���[�� ��-pWmL�"i� �vZ��#�A���p�~��J�~��amNw^�P�����s�E�Sh�ب������DP�g��HX�m��<hc����>0���Mͣ��К��h=��r��Uy��i�����khvㄠ��w�Ξ��G��\nƩU��fc�3 k�g����ďES)��cæ��iq`a�qM+��b:�l=3�f�������_N2�t��a�=1=C)�ޯ/�u[ɮ��'������Q�(���+*�_�&DXD�]RU��v���uR�2u���qT�/a�g�t ����=�7���8�R�ú��I�a��+C;�p,S�炯� e~	�C��Y`<��0B3
�!��n0f���h#w�� ;f�H���!�r�7��<l��:���޵�8��������3�3�{n[�KS�]�d�c;�ăFߒ8��8q�4Z9��8q��'j�.�vA��o xCb%x����1/�Њ7@<��[�.]U]�g����Uu|�s��������we��,3�݇�|V���ֽZ�
W�Y�[ߦ@�뵡���m5��xܱ���j�my�0} 2۽�-�//�ũ��7�y����+/��
�%��[ݺ�����E$z�Eu'���N\�D���?���?A�VO$�͓��Zf���'�/6v�����<�x��ޚ���j��e�2�����{o�4�z�I�d��)�FPr�y��)��)���T�u{^��e�<&X�fcePچ'�/6Y���>�R�tK���
+�8�)?sr<%���nD��%8w#�-��<�"��{�^�8�Z������em\�'=�B��D"��8���v������>�s�?�鏿x��)���h�:�bJE�*�"�4�ML�RѬS(����!F`T��`��Q8E!u2���(�C�|�68}a���^ښ�����-�p�u �Wy�7�� tv���/oA߽u�"�o�:������NF�[�+_����{�-/s�|��7���	�u+}yS�]'�)�uV�:o�~^��~��ן�'"�]��%��X>=�	4��� >��?%~�g��ƿ��ÿ&���[?����?��|�[_}�����1������[�n�\�W��y]a,���`D$ih
�`�I�����7"�8�]��1�Bq�6śJ�B��*�C�w~�ǟv�:��O�������~�������߅��a�a�� /m-LC���7Λ`��}������y|A,��}z����K�e���,r�\�[j�,�u�i�%.Y϶��b�6�TB�G���pt���A����$�����K��7z;m4��]uyrK���]�yUdz���r������s�ifN�b�:�.�k�[6[�I�2 &�);�����U�6K��~yk���jyگu�Y�k��|Չыc	�Ad�0=o%[�n�������81gQ!�O���i�[ªeĩǋ�*J�b�q����i�]-��W�uީ&V	�YZ�$#�hI�$��AGB��p�Ng���6҃V8�5�v�A�?J!s;��\���MǲI��O�:uК�b�I8-�/nE��d�b>'=v�+��uzlA��q�ļ?h�s��e�C;<���E�l	�]��m��'P���@tA-�;�FL$�қ��V������׹�{�<-��l��Ŷ�T^m0��&>�"1�}�5T�:O��:+�+�Z�	eR.�<����_'����SB_�y 5�hiT_����.�Mqo6��qR��8k�2�Y#��g�
i���)�I*��}I*���:�<�fZ�&	�2p���1��;N�}em�����{�.M(GSSFB�iAK���T�j���m�k�r^N2	+�)�H3_lV���)��a�"Y#k}��f
�0�<Q��Y\wRmYf�"�Ł738��w$ol:w��LwXS�$#0��'���M�lv�1B4�$��e|6ջN�|�$�$��>��U�*s
/S�U���k�\tJԄm�uA/�)���$g�^���^pD�@�$&r
l�X�"'�L1O_��y�XH�(t��'��x�D)p��	m�?��H�b�s��dj��g��Y���"v����Xnħs�ɞ������E�d��DO�I� O���\O\O��������1��|�L�#SM�jH&bd�,��̜ĄUN��F���P�������@`�����٠r�!���NOi�q��k��4⇬��f��)V U�3�y%��L,�U���AT�!N�%�'��4��`Tc>F��pw�#��91�Z�)c�G�d�;�@W�$=��L��j|<�*D�V��h�MNiv�M�;�]��Y�1�����ϻ&��t��y���×<�m��mN��-������v��B� �����i�ڭ��k�Π_�^vm˃u����W����JO:p������//B�]s��%�A����E��7�{l%��~��៬��܇������^�_Je�Ke�X�vt��G�cʳO�+D��������e~��k�Ϣ���Ė����M�s��h͢+<����5o3XR�������4WD��f�G��
�T��Lˌ������a�K�Rİ	��#�9&X"��9-֖ E��$ՠ�H&ۅ�z52�p�f�Z*A�ݺ���qǞ�0zm��n,�B?Y�!QTd:�d��B�/ĲR]3�����U�����ܶ>�ȴG����.ޅ�K�2J��w��]l�Cl)D���\�θj��k�i�ڙ�)pBP��1<m�FE�ur�x�[�n����V!�N%�j:���Ҩ�):*p�]�g�><��&n1���L-T�X��NbaU�Bx8�V�"}��7/�4��(�7��TM��ؕ�q:�G�ّ>n��g�������k��>� ��ti� s�Lk-�fV1X�����Ug�6?�p�Y��e²�۔9�6�^Owp�����`����{������X�_M��mr����{d�c9{�+f.�C��<Δj�dY-��:eC*���<��0��Ӛ]s������@r�5�v'\��D�:�dD~t��h�v��2�T�Y����r��Vr����S��R�Xb:���8D�[��kӉ�P�8J:O�gDu��`^Z���Sj%��ⵒ�L�;r���r�L�)8]eP��4���	�s2�'���0����5sl�@��NF`Tf%�MΥ��J'��K�DF���X���IW�[��Ť-%"��J�:�[A�s��J�Lck���]���B���.���	8փ/&�k���I�S��lۼ��BҊHŒ�b��ar<��)���!�;}���2�Ԥ����<$�Ť�B5�;�d�X�Z�9��'��[CO�\W���D9G���tUDB�4�探!���HzrNHx���S�����	��n
���F!� :�ĥ�t���R���t�BMs��0�5�W�&c�
��Ux�t��S[��5>�a�L���2U�rf��h2m��ȱ^�+��\�pK/}zy[uۜ�n�ƫ�9V��|�F�Ep��浑=4�t��x�Kஷ��Y����@݃��M4�*G�˛-'���K���Ǐ��?~���5������Ep=��^]d!+)��X��n���7�R���9}�K(��a鴩{�Z]O�+�����+���[Y�P�����ޣ;�?�n���jp6�� :o=i�m_��xa�/�M������=�W`W�������[!��k���o�B]��K����?������B�mF��u��〓GÞ�E%�©�s�4��i���G5�=nz�e��~اK����ȋ��J��7c�̭r��~n��jnGRt/~��Ⱥ�ʽ��G�M�P�����Y7�C=�n�r��=Q�]���Ⱥ�/�uSg�#�ިG�y�G�ͅG��G}�0�0�A�g�iúx�����Y�'���	] F�_x����sk��z&�����(�)�o�����u�o=�;�K���qR������.��'�LZ`����.�ʶ*�t�|�+*r,)N��8<B���Wr��]���j1��k�8_��K�<����^���R��ܶ�E�$=2�)L%��.
G���x��L��~j����[dþ��K�;��S�?����[���z�V��o��#`������D`����Cc�����/r�����	���e�mP�'\���HaⰣxʡ$�0,8�4��a��ԉ����Kp�h�x�4'f���y>%Y���,M�v$3��X��c
K��%�˚�P]����)Τ<>�c��K	4n�l�l{���E5TQ�0W��\B���ƈ���n��gn�茶?���ߎ(t�6���EPC1��`�{8��� 7�sCy�n��?�4�]���xb^W�c�A��������#��O����2e��w�I���?=�c����'���������)sN��G���������/���^:5��=@������(|����~�x���!?�����������`�_U�c��>�k{ �s�]�����	��cA�� �����=M�>�g��^��9�?�o'�S��B�+ �"���o�o/�;g�G������9,�{a���Y���A� �s���	�3�B�C���Nb��������(��3��������1�������	�/~v�{a������'�-ٖ�lK�ɶ���}6��/��}�����������[����߰'�l �	{a��������~��L��O�S��h���j�����������#ș��8���	���UE�G��x�CH�QoR���M�ьDqM#��b��l�)�=�cL�d��	�[������c�?B������w��<u���w5b.E`�>��*�2��g�)��5�T���8+���/�h5��%��b��(\ӕiCJ�a�F�'a"�$����Ų��c�M �Y����i=�6gB*+S��'�'�~y���������~������}������������O�_6��5�~
�/�����?<K��Qt��c�ZW8d*�P�6,;]7�Y�۱�X���_�/u��LV�t�갗��n��]	��K��ČDc����$"jx�jI�����4�d�Rh'>��iv��Cy6��������`��'�)�U�:�<>ԟ!�?{�֝��m�3��;Ɩ���<� ���������ӘtgG��N�NQ�Y�)1�"�YsV͵�/��*P��_P��_������Ѐ��'����������������ٮ���u�RfZW��8�W�r���OԵ�66��_hot�6~��F��mSiK��Mg�
4-���촟ֺ�������$Yc���0�����ф:�6�r�dc�j7h�a��M�h��i�kFc����V��:������Jmtu�庞q�M�N�����S�B>�4׫]ﻮ>i�ޭ���/�oGݾ�6�:�P�|�+�g]4_U�*����l�[3�kU�),Z�nW+}��ͣ69��̨PVU>��4ߩ��%���-{|���}sż�4jՎH�8��{����k���翜�x@��g�����8����#� ��/��Y�n�� I��8�����#y������I������a�#�,���w�a�&�X�a�� ����	��2w�!��	���<"��]����!������/�!����g��0�\��������_0�?�y D�������0��?�����#�����������
����������>�������c6�����?�	����h�g����?������/��?������p��ʐB��_8��w�?!��	��?��\����<�@�O,�����?@��b��]�/��P��Kg1Ԇ��_[���������3`�A�������?�����~��x5���l�i��fkS�ם�g�?��W�_���܌_�S8�`�Y���L�j@��O�Հȇt[U��^7;mȖ���(m��q'ium�v5�%��e����O�(�Lm�?-�A�X�ļ��t��b�;��k@�kȿ���E �T��ռsq�Ʋ4U�DuK=��|2Mq]�&[����i5Uk�@+�[�4!UV����,df�z@V{��yʆ�(��hȸN�O�_��D�?���������4�,�����#����?!��$�?4��"������,������?B�G����
���P��������_H�h�D�8�/���?B�ǯ"�����P��[��4��Bp�� ����$�?�<����� 9��+� N�"H�Q8�h���y�؈eiY	&�h$�Q$�/��"K�D�?��������?����+���X��-�߆1z��fM���lS;mͮ�+���J���ܨi&���ހ��=i,ug�Z���q"���I�{���y��M��N�-��(SJӎz=��J�͐-7q)Hv��屓�˻}�X.)s!X�4�9���aR��-��^��͎�q�j�q>4�h���z�Ԧ�n6����^T��0���C���P���-�з`�����+D�?��(������u��E_�/	��_q���/엃��ͺV�Д^^�h0לu�ifU�uG�D�g��}�b�r�^o�&I���~�/˕�i6�d����4ח��+ON���皻�f-����t���&MN�|�F��g���(�X�����?���`�'^��D俠��0@��A�����"�@�� p��
�{�op�q��kN�D���̖�� ���.�������R��\@��u@i�{�4�l��[�̤�T���鞖{��i5�+s�O
�(s�|,K�I��]o��Z���Eg5A���#�Kζ�-�mq��̣�:OCj^s�u���Z�F>�4׫��uO05U׫j�]y�/�zT42����c��Ȳ��<�.V�/�V��t�����5:��o�h��_��z�7�b<�/���w!=�j߾6���7�4��4�X�M�^��*R�<���Xg=����''�E�܊[�f��+B�[���5���F��O�Fm�o�wn�п�`�l�P�>~��	��8@��g������_,���=���������/N%��8 �`�����_����'��>EYfh.�Y�z����)#��d$ӗ�]0��E,#\ad��®O��������]a@������Uk�*1�Ю
�vl���b��e�t�;���V`��Q���s��˖�j�~V�@��GA���<Z���>���z�C���q�?���_� ��� 	��
w��"��� ���k�C�ɗr�D\���ü(ͳ4+FQ �!N��@��W�3�Y �����������b��q���3�Ӕ1��F}��E�}X?�b[��	;k����+�N+S?W������(�X�i�
��&{�
\��G�8���/������[��/�?	ߒ���������`������ov1�"����{��p�?$�?F��P��	����O�?���	x��'��J��@��4}����� ��f�=��B��_<�����_�P0�_'�}	�4�������U�� ��})�$������n���� �����l�����ȼ��x��_8�^�˝W*j�z��z�oMe�+e˺R�t���&�3�ζ��T��2�����FϾ��kƩ�����h0>+!���������v<������9:s�l�m-�}��v}������U`k��U���?��s`�]��5������-�ȫ�s�]^p����W$e��l����Y�^���eq���b���s�~�V��vZn�Sc,dyo;J�sΜ����2]��Zm��A�VZ���\�:�.��������)r"�J�z���j_�]�zMe�+[��"^����ՑIi��'�KP�w{�����g5���xÊ��D�r+�F\c3c�S�h���u!�nx��Z�ͩ9Z/�i��ߦ���GvT+��v��қg���QGE^
�Ҭ鉻R��t�s���+�9\� �à�e�\��!��^�-v+	{�F��O��?-F��{4����� ����5� ��_[���������`Q���I�	�� ��_H������������W��}k�wJ�IY3O��4���{W��u���S�/�_�����7J�Y�X�Ut{��3XgJ5W��צ�c��ܙ[�ݳ�V�b���O��/�Q���_�2~v+�z��x���}ۦ����dgh ��w*�1�O��*m����G�e�ű۳���Ar��Qc02Q�R�N�����Š/-;^4B�QE��l&��X'�.;]�J�I�#�y�d�yc��iM[�M�\�6��zok��گ{��sU���.ϳrwaW���vc��4KS�]����m�ꆁ�Z�]�����5���n�����2:VmëXn�O�HU�x��F!/��"��t=.I�%������ʡ2)�V��f��O�Muc$Ȱr[��]jطkmD�N^���~m׏���<���_, @�=5��b ��k�?"�_x������,����� | �����������~=�/};�7��Q���gL/;������-�����>ڃk��7 �Lm�� ��@�� �O�[O��KO�� �� �p���~MwL����,���f�x���iy�ZePc¦�=���-E���W=ď;�r���;��$�E�+���^� �H��*��ӈR<�9��-6]�R��	��%�����u��h����joT1dV�y+�<=��G�X��.�ˌ��X�)�}��lh��F&zc���Ԅ�t-���:����S6�����]�����������_�� �	��������?�����_���<�2��p� ��Oi�م�� �����H���{���, ���"}:�D?�I�h9��0
x_��B�Dy���� 1����R�L��8H��G��������F�V�lj�ͬ���H�[j��2��1��aY����i�kv�<���;TR�s:��-�UT�J�>��,7%?�)���NnG8	�e(x�k���t��6�}�ņ,
Բ��OM�֣�U��Ӎ]��o?
���Y
^��%�
��Ł����� ���޿.6���A���+���������˫�u#��R3
+�y{r�2�cvRc���_/\d�}w��|��cw��5�-���4��d��9V�m��5�1��Qr4�m{k���&�0����׷�y{j���?�����?@�?��� !��_�꿠�꿠��@������.����A�}>�������7���7}�2���uw��������W뿛��J;]kc�I��cH�H�.iz�E��%��P�"߭�?�kOMt;�Y�tt��c6�HwR~�:qc.���9S��:�i֌ń?�V9�mnr�^���+}���t�*����U���.U��שsզ�-h�H���:桯�̜�]=�Ϋؒe���n+ux����m��&}o�����2�p�s3ybe�|�S�c�8����R2��qC�iVg8ᘵ�D��ċeV�(*����P(��-�(G�D�������$�?�P��������J2p��������X@���� �CWR��_4�������+i��������W,���0�����B��x����L���`�� ����	�ϲ��v��/D��� ��A� ����C��?���0�T��������_��?�x!
$��G�_x���0���������+����A�?�>�x~r�������<�H��~���� �Á?������_���> ����C��P�'ܝ���WL������|ߧy��&h°!�HA�"��-�r�!B������;q$���O�몝��AH���$�anq����H�@HX��~�͔�6.��m`��څR��+��ʔDS���C&SRF���>�N�����|�Sl�}<���FMٛ�W��p>u)"��T���B�g&��>s�i������:bA�YhBk���3ӺeVJ#һ+��H�s�k.��o�4IJ�������!�cp#a��r�ף���Q�k7Iz^����V:��?�o�'������l��� N�1�?����;��S�=���B���x��iҡ�?��w�����������Ǎ�3�����;���j^B^��9r�ͩ)�L�T�1�V�*)�l.��L�̍i�Ngi9��L��/|����/���8�g����覫���Kz�;���%�����hI�I��l��Ka��g���]f,
�3ώ��p�6{4�j�1"�U�z�45Kbʥ���J��U�s=��Z_�'F���d.o$��'��Q���o�S���������g����*b�&�O����!��"�����A����|����cS��1�������������!�L1���t�O�Y���?�����G��c�?:����b�?�������?z�E��������������������{����p:��ѵ��Ǣ���������P6v�?>�� tR��?S�@:���PR���^��C��������.��ˎ3T��6�V�gu����������3����u�ٽ'^��[�ro�=�2����Eިkw�۾�AI�b�K���Le����l��gj���)�>_șw�Af�4��-/H�S2�L�Q���'v�{��Y?���|�e�j��O9��W,vǍ'6~�[��b(�+���T��"�t>�]N�gʄ��ɬ>��\���R�,�Vg����u>�p\?�F������;j%ϯG�կ��a�*������R���_���A�쿭���7~=���_��;	�O����<��ǧD�N���w�����!(>�)>�)>�)>�)��c��H������������m����������?�����S������ѫ��������"��f�q�V�\im�duK������5���B�~R����J�g�Љֺ��1�K�y�4V�)��)�B�ӹ�̋ȿ5�TnU�7a�+���ѽ��n&��sF��T��U��Ja�zW��6ߛ�/O�F����i��w+d�[�8m���4b0�d���P��el�2��?hDW���Q
nD|��E���\��UW\;U��:�zߪ-��}XL�n�0!b��+��٠�5��x(U�jQR;���gG���/��lũ�-13b�uI��n���Y�D`����-k���b�c�9���l�w_��gu��V��=��,W��-�f~u~��w�R��M�䋙�N]�ˌ$yu�zh:�%5�.��J�g�j;C��v'w���I��� �����l���s����%�&���IW3ּq�V��%,$����Y�C����D�k��g�j�'���?����R{�����x:�o׎k�0���@���k�����Y�������)�:�SYe�N�
�I��\Zfri2��ː�������S:CK��BѲB�JFI�yZ&!#���������z�����ڨ:]��J���XNni��W�9�?��~yZ���ir����o�rj�\2�d)���jo�/��(�Imd�nV��R1��ܤyٱ����P��Zdk-U^$��Vr=S\U$����V:��?>��xt���5�Eߣ�)����w<:	����8� ���&�x�����?���G���y��������hY�Cx#q�a�LoV�Ŝ�FS%݁��m�?�Fg�B��ZI=+5�N�:�h\�$�>9!�~GWx~5bșF��C7�V���+���ng0�3���m�%�L�+�ұ��V:�����G���)����}��@���W���x���������_q�'�����m�c�I���3��N���!�5�ot��?-���Kc��JЛ�dk�BJЅ�������(��߳�����):��&f $��= Ķ=�w 2U�R�P��^K��� ^����c�{U6y^s-�zo�Ԍ���1�:/&��_��i�SK��B�k�_�VoXA=Ϧג\����!�mO�לO���ڨ�ǾhQ�9�A{y���+r~�C���iB�C�'�N߰a�IIl9�i-�(-�\AΥ�]�r�sB��r��&�i:�Wu��@�nO��9_49ctS��5��M���N��m�"��d���dN����|8��9]���IX���]�Y8�f�չ)�'a�jv�<�awn������r�����`=�^W���i4���?���ƫe����,C��?�f�l����O��k[�&.�pute/�5 �4�0�5A|">�N�psQ�h:�B���:�/���	��$ʇ2^�!ngM[�v`j8g��X7ulp k�m�%S�tSC��3��T�s���sI ��1����}�^n� @��K�y	�� �����:��؁�B�24,�-`�1�� �а~Pm��\?qǔ-�5�Ήd��y��7K1��?D�75�(��R*��G�}�v|��~���j?G�
܉� *�����$%C��CWt�ȶM��:@7����_8Q{v W	 �(��;����.��I�Q�I.�=�ƐC�'h6@5�L ٶ���DT/�֡�xhxL[�W	eu}���P#}��D� �"�;O���t'��㋠Q8�����b����'����,3��/� 2$�kP<A���Q�<���l[W!��������}�w������軌/wz�t���M�}K��P��};�.��>�d�E壾]J��8��yP���h��8!�����Y`A[Bc��0��Bۧ�?�,����A1���<�m5e{�Q^*�s��s����u���%	U�]h �r�$�<{�$K���.�8|A���;�D�����j�-FP�N$�E�R�!�������F�d�a x҃$�k�aY3�W�Ap����T�§H<���Ej#vC�C���Q/q-Mo.�i�0�	��࡯�7���R7U�_:��k�.j��{x�Q��\�Sܐ?V�/�1���Q���4��FE`�;ƴ\0�\w���E+6�:�r'�ҝ�.]B�2�0�u.ˏ���
!:bڕP*�\_�T^�Cw0����Ɓp�.A*�Dڍ���U�[�F�������a������ԩ�繏ӥ��;��V )
��[4K�h�-�����Q��'�������]K�tCM���E�_��I&�<������0��A����A�"
�\%�{d8Y��,'V�[�X�m�����֠@���fw������U>����,�b�Q.,�]x.gX�$��B�'d|����d��ذ�����m�J��$l~W
`s;J9~0������a�=^'�>�����P�-a2�ׂ�4�M���#���K��A`��!{b�}.ihR���6��!��DF�.?�"_F��`���\�eb��1β��ܬWI�*ɽ�"���`G���5X�bOe�O�{
G⋕�
�,u�x*���
�+G�(U��LI����)(�iH�Ǚ�XQ�8�f�)I�d���Ty,���arP�2ҭ3#��8��:˒i��	"f@�%p&�oO���x6�������;�?�9��c��Kr&-ɲL292�Jj���BJyI�2&�d.���$��La�F=��C&SRF��c����/��\�����o��+��+݊��|kk�!0����N�'�(c�|��O�ߓ����x��6ł "�.	Adk��f�&�ڕ
eO{9[��l� 
����{17��S�ԅn�Y���Z��굱^�,^n���V�pY,���܅���
�p����o�3�ު�}	���Mj�Br'I�V�r�<9���c����V����#'����;��b�鮝l�`=�yl)���G��9��ԧ=�J����~yߟ����M���(`!/U�����2[i���c�P'
�+�f��o�F�լ4�W���.��$��$����=3��ζ|O��o�D~���y7��Bo"�H=�[��Wѣ�f��7�J�!tM�ZG��ڨ���Ӿ[��h�m�ȳRC���L"p���q�B	=��]!�[`�,�v�+��*����|�Ǘ\Ԧ�j�A
~\�/���
��n�0�┋���ˡ�Wc�p�*��$tA��%�~��]���z�g�</��8�d��:�~X	n�U�����"+��;_�)�H$0m�c�l��>�lX<E�'#���Q��Q���5T���L�9L2�@%���nq�̍}���B�V-�,7���xe�g*����Q)���T
�hd����!��$e�Lʒ3��m+�$f��n;.��mٿ����.�c�nN��k'p��)@*x�@����gC���?� 2}1�'�\�%9�v+�m��M�(�e����>�
�?�N����?ėo;͞�� ����z����U���L<�
	f��L�������y.t\T���?P����ðҁ��� ���a0�azT�7e�U�����Z���
�����'yEc�_2�P� �o�ah4��M4,RЈ�nf��b����V����)�h�^����ڞ��󗝛 #�_���W�hhy��KuMs>P(��d�_�ފ��k-~�1���?��g��i�B�O�:��C�	��a&�`){��(?T�Xd#�����9�Y�=�q��a����`q�3,`��|3������?2�0��0x�����B�����U�W\�L,�Z�@e�hP@�P�p�G��Fђ�ےL�B�	���3�ߒH���g�����<�}q�a�@�g࢘ ����|�L�w*���Է0.���>�{W֛6���W���RU@ll�T�!��ڗ�RԾTyX�B�p�"E��ޙ��6��5��ޝ��s�� �r�_�8�秗�$�m`�ݶl�ȼ���d�n�][]G�b��wZ�)���M�f�e>,��%w�&������L��(b��[ez_>�U&��L pE��/l���$F�7����,����J�<��1c������w�)?[NctIS���,�3��$>#�1Zň����z�b�Z��R���X%�a�8��RP��O�7z蕥J�m'!��@Z�F9W�x���t£�_g�	6J-����ҽeS���=<���ژ�_k��%�T|�E��%޷y�L��T�WK��9�0���_����'�&��r45��T��g���8�����xN0
�j�� ��mOyn��z�J7�����Iٗ���a��z���"��U5T���p�	(3ޜ�̜>�;�}�K�*��;�fy�QF�W�B�\�4�bC�n^��ג���F��ijy��_-�e��h��H������jD[.^�Y��7����&���٥�P������ٿ����T�֬���������<�o����_�
��w�����x��d��U��}����K���y�>x?����}��K4Flz��¸" ��`�$d�heYtrӭq����k�%��0�ոd���*�D�\1=���
��=Yc�Ӧ��?ч��	�����ief�}�x��LΏ�AvL� N����$�@ �@ �@ �_�o���� 0 