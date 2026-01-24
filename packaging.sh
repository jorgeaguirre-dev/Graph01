# Limpiar si existe algo previo
rm -rf package function.zip

# 1. Instalar dependencias en carpeta 'package'
pip install --target ./package -r requirements.txt

# 2. Comprimir dependencias (sin la carpeta 'package' misma, solo su contenido)
cd package
zip -r ../function.zip .
cd ..

# 3. Agregar tus archivos de lógica al nivel raíz del zip
zip function.zip app.py schema.graphql