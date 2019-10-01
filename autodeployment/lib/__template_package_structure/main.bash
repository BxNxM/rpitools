#!/bin/bash

MYPATH="${BASH_SOURCE[0]}"
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conf_factory_example="$MYDIR/config/orig/template.config"

# RPIENV SETUP (BASH)
if [ -e "${MYDIR}/.rpienv" ]
then
    source "${MYDIR}/.rpienv" "-s" > /dev/null
    # check one var from rpienv - check the path
    if [ ! -f "$CONFIGHANDLER" ]
    then
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!"
        echo -e "[ ENV ERROR ] \$CONFIGHANDLER path not exits!" >> /var/log/rpienv
        exit 1
    fi
else
    echo -e "[ ENV ERROR ] ${MYDIR}/.rpienv not exists"
    sudo bash -c "echo -e '[ ENV ERROR ] ${MYDIR}/.rpienv not exists' >> /var/log/rpienv"
    exit 1
fi

echo -e "Execute test main script"

# Dinamic patching example - export placeholders with variables
"${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/template.config.data" "init" "{USER}" "Wilma"
"${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/template.config.data" "add" "{SEX}" "female"
"${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/template.config.data" "add" "{USER2}" "Fred"
"${EXTERNAL_CONFIG_HANDLER_LIB}" "create_data_file" "$MYDIR/config/template.config.data" "add" "{SEX2}" "male"
#################################
#     CONFIG FILES STRUCTURE    #
#################################

# STORED
# .factory              - saves and check factory config/settings - automatic
# .finaltemplate        - final template file with placeholsers - manual

# GENERATED
# .data                 - data for fill placeholders: syntax: {placeholder_name}=value
# .final                - .finaltemplate filled placeholders
# .finalpatch           - .final + .factory diff

# Execute patching workflow
"${EXTERNAL_CONFIG_HANDLER_LIB}" "patch_workflow" "$conf_factory_example" "$MYDIR/config/" "template.config.finaltemplate" "template.config.data" "template.config.final" "template.config.patch"
