#!/bin/bash

WORK_DIR=/src/ldap/edu
TMP_DIR=/tmp/ldif_output
CONVERT_CONF=$TMP_DIR/ldap_schema_convert.conf

mkdir -p $TMP_DIR

# Generate the schema conf file
for schema in $WORK_DIR/*.schema ; do
        echo "include $(realpath $schema)" >> $CONVERT_CONF
done

mkdir -p $TMP_DIR/fixed

# Convert the schema to ldif files
slaptest -f $CONVERT_CONF -F $TMP_DIR
rm -f $CONVERT_CONF

# Clean up ldif files and import
pushd $TMP_DIR
cat > fixit.sed <<EOF
s~dn: cn=\{([0-9]+)\}(.*)$~dn: cn=\2,cn=schema,cn=config~g
s~cn: \{([0-9]+)\}(.*)$~cn: \2~g
s~^(structuralObjectClass|entryUUID|creatorsName|createTimestamp|entryCSN|modifiersName|modifyTimestamp):.*$~~g
EOF
for f in $(find cn=config/cn=schema -type f -name \*.ldif) ; do
        mkdir -p $(dirname fixed/$f)
        sed -rf fixit.sed "$f" > fixed/$f
done
for f in $(find $TMP_DIR/fixed -type f) ; do
        ldapadd -Y EXTERNAL -H ldapi:/// -f $f
done
popd

rm -Rf $TMP_DIR
