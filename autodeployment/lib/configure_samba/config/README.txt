#################################################################################
#                         STRUCTURAL DESCRIPTION                                #
#################################################################################
*.factory                       - factory backup for patch validation
*.final                         - final patched and filled factory backup
*.final.template                - final template for patch generation
*.patch                         - generated patch

############################# Way of Work #######################################
Generate patch:
--------------
diff *.factory *.final.template > *.patch

Patch factory config:
---------------------
cp -f *.final.template *.final
smartpatch *.final *.patch
