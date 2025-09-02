# Guía de Gestión de Fork para Chatwoot

Esta guía establece las mejores prácticas para mantener nuestro fork de Chatwoot de manera organizada y sincronizada con el repositorio upstream.

## Estructura de Ramas

### Ramas Principales

- **`develop`**: Rama limpia que se mantiene sincronizada con upstream/develop
- **`custom/main`**: Rama principal para nuestras personalizaciones y modificaciones
- **`custom/feature-*`**: Ramas para características específicas o experimentos

### Principios Fundamentales

1. **La rama `develop` permanece limpia**: Solo contiene código del upstream, sin modificaciones locales
2. **Todas nuestras modificaciones van en ramas `custom/*`**: Esto permite un control claro de nuestros cambios
3. **Sincronización regular**: Mantenemos actualizado nuestro fork con los cambios upstream

## Flujo de Trabajo

### Configuración Inicial

```bash
# Agregar el repositorio upstream (solo una vez)
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Verificar remotos
git remote -v
```

### Sincronización con Upstream

```bash
# Cambiar a develop
git checkout develop

# Obtener cambios del upstream
git fetch upstream

# Mergear cambios del upstream
git merge upstream/develop

# Actualizar nuestro fork en GitHub (bypass del hook de protección)
git push origin develop --no-verify
```

> **Nota sobre el hook de protección**: El repositorio tiene configurado un hook de husky que previene pushes directos a `develop` para evitar modificaciones accidentales. Durante la sincronización legítima con upstream, usamos `--no-verify` para saltarnos esta protección.

### Trabajar con Personalizaciones

```bash
# Crear nueva rama de característica desde custom/main
git checkout custom/main
git checkout -b custom/feature-nueva-funcionalidad

# Hacer cambios y commits
git add .
git commit -m "Descripción del cambio"

# Mergear de vuelta a custom/main cuando esté listo
git checkout custom/main
git merge custom/feature-nueva-funcionalidad
```

### Aplicar Cambios de Upstream a Nuestras Personalizaciones

```bash
# Actualizar develop con upstream
git checkout develop
git fetch upstream
git merge upstream/develop

# Rebase nuestros cambios sobre la nueva base
git checkout custom/main
git rebase develop
```

## Archivos que NO deben estar en el Control de Versiones

### Archivos de Configuración Local
- `.env` (credenciales sensibles)
- `config/database.yml` (si contiene credenciales)

### Archivos Compilados/Generados
- `public/assets/` (excepto assets específicos personalizados)
- `public/packs/`
- `public/sw.js`
- `public/manifest.json`
- `tmp/`
- `log/`

### Archivos de Dependencias
- `node_modules/`
- `.bundle/`

## Estructura de Commits

### Formato de Mensajes de Commit

```
tipo(alcance): descripción breve

Descripción más detallada si es necesaria.

- Cambio específico 1
- Cambio específico 2
```

### Tipos de Commit
- **feat**: Nueva funcionalidad
- **fix**: Corrección de bug
- **docs**: Cambios en documentación
- **style**: Cambios de formato (espacios, comas, etc.)
- **refactor**: Refactorización de código
- **test**: Añadir o modificar tests
- **chore**: Tareas de mantenimiento

### Ejemplos
```bash
git commit -m "fix(migración): comentar línea problemática de ActsAsTaggableOn

- Resolver problema de compatibilidad de versión en migración add_cached_labels_list
- Permite que las migraciones se ejecuten sin errores durante configuración de desarrollo"

git commit -m "feat(config): agregar configuración de entorno de desarrollo

- Configurar conexión PostgreSQL para desarrollo local
- Habilitar registro de cuentas para testing
- Configurar URL del frontend correctamente"
```

## Resolución de Conflictos

### Cuando hay Conflictos durante Rebase

1. **Identificar archivos en conflicto**:
   ```bash
   git status
   ```

2. **Resolver conflictos manualmente** en cada archivo

3. **Marcar como resuelto**:
   ```bash
   git add archivo-resuelto.rb
   ```

4. **Continuar rebase**:
   ```bash
   git rebase --continue
   ```

### Estrategias de Resolución

- **Priorizar cambios upstream** para funcionalidad core
- **Mantener nuestras personalizaciones** para características específicas
- **Documentar decisiones** de resolución para futuras referencias

## Manejo de Hooks de Protección

### Hook de Pre-push

El repositorio incluye un hook de husky (`bin/validate_push`) que previene pushes directos a las ramas `develop` y `master`. Este es un mecanismo de protección para evitar modificaciones accidentales.

#### Cuándo usar `--no-verify`

- **Sincronización con upstream**: Cuando actualizas `develop` con cambios del repositorio oficial
- **Emergency fixes**: En casos excepcionales donde necesites hacer un push urgente

#### Comando seguro para sincronización

```bash
# Solo para sincronización legítima con upstream
git push origin develop --no-verify
```

> ⚠️ **Advertencia**: Solo usa `--no-verify` cuando estés seguro de que el push es legítimo. El hook existe para proteger las ramas principales.

## Mantenimiento Regular

### Tareas Semanales
- [ ] Sincronizar rama `develop` con upstream
- [ ] Revisar y actualizar ramas `custom/*` si es necesario
- [ ] Limpiar ramas de características mergeadas

### Tareas Mensuales
- [ ] Revisar y actualizar esta documentación
- [ ] Evaluar si hay nuevas características upstream que queremos adoptar
- [ ] Cleanup de archivos no necesarios en el repositorio

## Recursos Adicionales

- [Git Flow Documentation](https://git-scm.com/docs)
- [Chatwoot Contributing Guidelines](https://github.com/chatwoot/chatwoot/blob/develop/CONTRIBUTING.md)
- [Semantic Versioning](https://semver.org/)

## Historial de Cambios

### 2025-09-01
- Creación de la guía inicial
- Establecimiento de estructura de ramas custom/*
- Implementación del fix de migración para ActsAsTaggableOn
- Documentación del manejo de hooks de protección durante sincronización
- Actualización del proceso de sincronización con `--no-verify` para bypass de hooks

---

*Última actualización: 2025-09-01*
