##### Requirements

### Host environment

  * pyaml

### help

``make help``

### development

``make create_dev``

### production

Currently for ``systemd`` managed services using ``daphne`` and with ``nginx`` as web server.

``sudo -E make create``

``sudo -E make populate # (to load dev data)``

##### Architecture

CLI:Input Action -> SER:Old_state_TO_New_State -> SER:Output_Action -> CLI:Reducer -> CLI:NewState -> Listener


| Action                | Actor                              |  Others  |
|-----------------------|------------------------------------|----------|
| Login                 | Fill                               |AddUser   |
| Logout                | Empty                              |RemoveUser|

