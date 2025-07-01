#!/bin/bash
# shellcheck source=/dev/null
# shellcheck disable=SC1090,SC2154

# Verifique se o usuário é root (UID 0)
if [[ $EUID -ne 0 ]]; then
    echo "Deve executar como Super Usuário."
    exit 1
fi

# Variáveis para o ambiente
ecfreceb="/Zanthus/Zeus/pdvJava/ECFRECEB.CFG"
emul="/Zanthus/Zeus/pdvJava/EMUL.INI"
lib="/Zanthus/Zeus/lib"
lib_E1="$lib/libE1_Impressora.so.01.08.00"
lib_co5="/Zanthus/Zeus/lib_co5"
lib_ubu="/Zanthus/Zeus/lib_ubu"
# Pacote completo, E1+so do ftp
# lib_drp="https://www.dropbox.com/scl/fi/rmbivfskvutepdzlo8126/so_u64_E1-01.08.00.tar.gz?rlkey=ztpt0x6yvpcmt14ozsfqd1y25&st=cvhizhk0&dl=0"
# Pacote apenas com biblioteca E1
pacote="so_u32_E1-01.08.00.tar.gz"
busdev='20d1:7008'

# Exportar variáveis do ambiente
export ecfreceb
export emul
export lib
export lib_co5
export lib_ubu
export pacote
export busdev
# export lib_drp

source "$ecfreceb"
source "$emul" &>>/dev/null

# Verifica se IRQ equivale a Elgin i9
# if [ "$busdev" == "20d1:7008" ]; then
if  lsusb -d "$busdev" ; then
    # echo "Elgin i9"
    # Verifica se biblioteca diferente de izrcb_R82 e configura
    if [ ! "$biblioteca" == "izrcb_R82" ]; then
        echo "Configurando IZ para R82..."
        echo -e 'biblioteca=izrcb_R82\n' >"$ecfreceb"
        echo "Configurando EMUL.INI..."
        # Verifica SE o parâmetro FW_INVERTE_GAVETA já "existe" e NÃO está comentado
        if grep -q "^[^#]*FW_INVERTE_GAVETA" "$emul"; then
            # SE o parâmetro FW_INVERTE_GAVETA já "existe" e NÃO está comentado...
            # Adiciona as configurações necessárias mantendo FW_INVERTE_GAVETA
            {
                echo -e 'FW_FLAGS=2'
                echo -e 'FW_MODELO_IMPRESSORA=0'
                echo -e 'FW_PORTA_USB'
                echo -e 'FW_INVERTE_GAVETA'
            } >"$emul"
        else
            # SE o parâmetro FW_INVERTE_GAVETA "NÃO" existe ou ESTÁ comentado...
            # Adiciona as configurações necessárias sem o parâmetro FW_INVERTE_GAVETA
            {
                echo -e 'FW_FLAGS=2'
                echo -e 'FW_MODELO_IMPRESSORA=0'
                echo -e 'FW_PORTA_USB'
            } >"$emul"
        fi
    else
        # Se biblioteca equivale a izrcb_R82, verifica configuração padrão.
        # Verifica SE o parâmetro FW_INVERTE_GAVETA já "existe" e NÃO está comentado
        if grep -q "^[^#]*FW_INVERTE_GAVETA" "$emul"; then
            # Adiciona as configurações necessárias mantendo o parâmetro FW_INVERTE_GAVETA
			# cmd
			sed -i "s/FW_FLAGS=""$FW_FLAGS""/FW_FLAGS=2/" "$emul"
			sed -i "s/FW_MODELO_IMPRESSORA=""$FW_MODELO_IMPRESSORA""/FW_MODELO_IMPRESSORA=0/" "$emul"
			# cmd
        else
            # Adiciona as configurações necessárias sem o parâmetro FW_INVERTE_GAVETA
			# cmd
			sed -i "s/FW_FLAGS=""$FW_FLAGS""/FW_FLAGS=2/" "$emul"
			sed -i "s/FW_MODELO_IMPRESSORA=""$FW_MODELO_IMPRESSORA""/FW_MODELO_IMPRESSORA=0/" "$emul"
			# cmd
        fi
    fi
    # Configura bibliotecas so_u64+E1
    # Verifica se o diretório "lib" existe
    if [ -d "$lib" ]; then
        # Verifica se a biblioteca "lib_E1" existe no diretório "lib"
        if [ -f "$lib_E1" ]; then
        # Se a biblioteca "lib_E1" existe no diretório "lib", não faz mais nada.
            echo "Biblioteca $(basename $lib_E1) está atualizado..."
        else
        # Se a biblioteca "lib_E1" não existe no diretório "lib", é adicionado usando o pacote pré configurado.
            echo "Copiando bibliotecas..."
            tar -zxf "$pacote"
            mkdir -p "$lib"
            mkdir -p "$lib_co5"
            mkdir -p "$lib_ubu"
            rsync -ahz --info=progress2 so/ "$lib"/
            rsync -ahz --info=progress2 so_co5/ "$lib_co5"/
            rsync -ahz --info=progress2 so_ubu/ "$lib_ubu"/
            chmod -R 777 "$lib"
            chmod -R 777 "$lib_co5"
            chmod -R 777 "$lib_ubu"
            ldconfig
        fi
    else
    # Se o diretório "lib" não existe, dá mensagem de erro e sai sem fazer nada
        echo -e "Diretório \"$lib\" não existe!"
        exit 1
    fi
# Se IRQ "NÃO" equivale (É DIFERENTE) a Elgin i9, faz ABSOLUTAMENTE NADA.
fi
