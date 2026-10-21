# KDE Plasma Workflow Rules

- Cuando se realicen modificaciones en plasmoides, componentes QML de KDE Plasma o Kirigami que deban reflejarse en el panel o escritorio, reiniciar automáticamente el servicio de plasmashell:
  ```bash
  systemctl --user restart plasma-plasmashell.service
  ```
