# Schnellstart Image-Erstellung #

- [Vorbereitung](#Vorbereitung)
- [Image bauen](#Image-bauen)
- [Aktualisierung](#Aktualisierung)
- [Arbeiten an Zielquellen](#Arbeiten-an-Zielquellen)
- [Übersicht über globale Konfigurationsdateien](#Übersicht-über-globale-Konfigurationsdateien)

## Vorbereitung

### Erforderliche Host-Pakete installieren (Debian 11)

> :memo: **HINWEIS:** Bei Verwendung der Tuxbox-Builder-VM (welche nicht zwingend erforderlich ist), springe bitte zu [Schritt 1](#1-Init-Skript-klonen). Die Tuxbox-Builder-VM enthält bereits erforderliche Pakete. Details und Download von Tuxbox-Builder VM siehe: [Tuxbox-Builder](https://sourceforge.net/projects/n4k/files/Tuxbox-Builder)

```bash
apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python python3 python3-pip python3-pexpect xz-utils debianutils \
iputils-ping python3-git python3-jinja2 libegl1-mesa pylint3 xterm subversion locales-all \
libxml2-utils ninja-build default-jre clisp libcapstone4 libsdl2-dev doxygen
```
Zur Verwendung mit anderen Distributionen siehe: [Yocto Project Quick Build](https://docs.yoctoproject.org/3.2.4/ref-manual/ref-system-requirements.html#supported-linux-distributions)

#### Empfohlene Zusatzpakete zur grafischen Unterstützung und Analyse (z.B. mit Kdevelop, Meld):
```bash
apt-get install -y gitk git-gui meld cppcheck clazy kdevelop
```

### Optional: Falls kein konfiguriertes Git vorhanden ist, gib bitte Deine globalen Git-Benutzerdaten ein:
```bash
git config --global user.email "you@example.com"
git config --global user.user "Dein Name"
```

## Image bauen:

> :memo: **Hinweis:** Einige Pfade basieren auf Vorgaben, die vom Init-Script erzeugt werden. Einige Einträge werden als ```<Platzhalter>``` dargestellt, die entsprechend angepasst werden müssen.

> ### 1. Init-Skript klonen.
```bash
git clone https://github.com/tuxbox-neutrino/build.git
cd build
```

> ### 2. Init-Skript ausführen
```bash
./init.sh
cd poky-3.2
```

> ### 3. Liste möglicher Maschinentypen anzeigen
```bash
ls  build
```

> ### 4. Umgebungsskript ausführen
```bash
. ./oe-init-build-env build/<Machine-Type aus der Liste von Schritt 3 hier eintragen>
```

> ### 5. Bauen
```bash
bitbake neutrino-image
```

Das kann eine Weile dauern. Einige Warnmeldungen können ignoriert werden. Fehlermeldungen, welche die Setscene-Tasks betreffen, sind kein Problem, aber Fehler während der Build- und Package-Tasks brechen den Prozess in den meißten Fällen ab.  [Bitte melde in diesem Fall den Fehler oder sende Deine Lösung an uns](https://forum.tuxbox-neutrino.org/forum/viewforum.php?f=77). Hilfe ist sehr willkommen.

Wenn alles erledigt ist, sollte eine ähnliche Meldung wie diese erscheinen:
```bash
...
NOTE: Tasks Summary: Attempted 4568 tasks of which 4198 didn't need to be rerun and all succeeded.
...
```
**Das war's ...**

Erstellte Images und Pakete sind zu finden unter:
```
~/build/poky-3.2/build/<machine>/tmp/deploy
```
oder im dist-Verzeichnis:
```
~/build/dist/<Image-Version>/<machine>/
```

## Aktualisierung
> :memo: Manuelle Aktualisierungen für beliebeige Ziel-Quellen sind nicht erforderlich. Dies wird automatisch bei jedem aufgerufenen Ziel mit Bitbake durchgeführt. Dadurch werden auch immer erforderliche Abhängigkeiten aktualisiert. Wenn man die volle Kontrolle über bestimmte Ziel-Quellen haben möchte,  siehe [Arbeiten an Zielquellen](#Arbeiten-an-Zielquellen)!

Falls [Schritte 1 bis 4](#3-Liste-möglicher-Maschinentypen-anzeigen) bereits ausgeführt wurden, ist nur Schritt 5 erforderlich:

### Update Image
```bash
bitbake neutrino-image
```
	
### Update Ziel
```bash
bitbake <target>
```

### Meta-Layer-Repositories aktualisieren
Die erneute Ausführung des Init-Skripts aktualisiert die enthaltenen Meta-Layer auf den Stand der Remote-Repositories. 
```bash
cd $HOME/build
./init.sh
```	
Die angestoßenen Update-Routinen des Init-scripts sollten nicht festgeschriebene Änderungen vorübergehend stashen bzw. rebasen lokale Commits auf die Remote-Änderungen. Konflikte muss man jedoch manuell auflösen. Natürlich kann man seine lokalen Meta-Layer für Meta-Neutrino- und Maschinen-Layer-Repositories manuell aktualisieren und modifizieren. 

> :memo: **Hinweis:** Konfigurationsdateien bleiben unberührt. Neue oder geänderte Konfigurationsoptionen werden nicht berücksichtigt. Bitte überprüfe ggf. die Konfiguration.

## Arbeiten an Zielquellen
Wenn man die volle Kontrolle über die Ziel-Quellen haben möchte, sollten die Quellcodes in den Workspace verschoben werden. Siehe 
[devtool](https://docs.yoctoproject.org/current/ref-manual/devtool-reference.html) und insbesondere [devtool modify](https://docs.yoctoproject.org/current/ref-manual/devtool-reference.html#modifying-an-existing-recipe).

## Konfiguration zurücksetzen
Wenn Du deine Maschinen-Konfigurationen zurücksetzen möchtest, benenne bitte das conf-Verzeichnis um (Löschen wird nicht empfohlen) und führe das Init-Skript erneut aus.
```bash
mv $HOME/build/poky-3.2/build/<machine>/conf $HOME/build/poky-3.2/build/<machine>/conf.01
cd $HOME/build
./init.sh
```
	
## Neubau eines einzelnen Ziels erzwingen
In einigen Fällen kann es vorkommen, dass ein Target, warum auch immer, abbricht. Man sollte deswegen nicht in Panik verfallen und deswegen den tmp-Ordner und den sstate-cache löschen. Das kann man auch für jedes Target einzeln machen.

> :memo: Insbesondere defekte Archiv-URL's können zum Abbruch führen. Diese Fehler werden aber immer angezeigt und man kann die URL überprüfen. Oft liegt es nur an den Servern und funktioneren nach wenigen Minuten sogar wieder.

Um sicherzustellen, ob das betreffende Recipe auch tatsächlich ein Problem hat, macht es Sinn das betreffende Target komplett zu bereinigen und neu zu bauen. Um dies zu erzwingen, müssen alle erzeugten Paket-, Build- und Cachedaten bereinigt werden.
```bash
bitbake -c cleansstate <target>
```
anschließend neu bauen:
```bash
bitbake <target>
```
	
## Vollständigen Imagebau erzwingen
Wenn Du einen kompletten Imagebau erzwingen möchtest, kann man das tmp-Verzeichnis löschen (oder umbenennen):
```bash
mv tmp tmp.01
bitbake neutrino-image
```
Wenn man den sstate-cache **nicht** gelöscht hat, sollte das Image in relativ kurzer Zeit fertig gebaut sein. Daher wird empfohlen, den sstate-cache beizubehalten. Das Verzeichnis wo sich der sstate-cache befindet, wird über die Variable ```${SSTATE_DIR}``` festgelegt und kann in der Konfiguration angepasst werden. 
	
Dieses Verzeichnis ist ziemlich wertvoll und nur in seltenen Fällen ist es notwendig, dieses Verzeichnis zu löschen. Bitte beachte, dass der Build in diesem Fall sehr viel mehr Zeit in Anspruch nimmt. 
> :bulb: Man kann Bitbake anweisen, keinen sstate-cache zu verwenden.
```bash
bitbake --no-setscene neutrino-image
```
oder
```bash
bitbake --skip-setscene neutrino-image
```
	
## Bei Bedarf anpassen
Es wird empfohlen, zum ersten Mal ohne Änderungen an den Konfigurationsdateien zu bauen, um einen Eindruck davon zu bekommen, wie der Build-Prozess funktioniert, und um die Ergebnisse zu sehen.
Die Einstellmöglichkeiten sind sehr umfangreich und für Einsteiger nicht wirklich überschaubar. Das Yoctoproject ist jedoch sehr
umfassend dokumentiert und bietet die beste Informationsquelle.
	
**Wichtig für Entwickler**: "[Arbeiten an Zielquellen](#Arbeiten-an-Zielquellen)"!

> :memo: **Bitte ändere nicht die Yocto-Recipes! Dies wird vom Yocto-Team nicht empfohlen, aber man kann zum Vervollständigen, Erweitern oder Überschreiben von Meta-Core-Recipes [.bbappend](https://docs.yoctoproject.org/3.2.4/dev-manual/dev-manual-common-tasks.html#using-bbappend-files-in-your-layer)-Dateien verwenden.**

### Übersicht über globale Konfigurationsdateien
Für die lokale Konfiguration werden diese Konfigurationsdateien innerhalb der Build-Verzeichnissen benötigt:

> $HOME/build/poky-3.2/build/```<machine>```/conf/local.conf

Diese generierte local.conf enthält nur wenige Zeilen, besitzt aber eine Zeile, die auf eine gemeinsame Konfigurationsdatei zeigt, die für alle Images und unterstützten Maschinentypen gültig ist und kann man mit eigenen Optionen füttern.
	
> $HOME/build/local.conf.common.inc

Diese **.inc** Datei wurde aus der geklonten Beispieldatei beim erstmaligen ausführen des init-Scripts erzeugt.

> local.conf.common.inc.sample

Diese Beispieldatei sollte unberührt bleiben, um mögliche Konflikte beim Aktualisieren des build-Repositories zu vermeiden und um zu sehen, was sich geändert haben könnte.
	
Nach einer Aktualisierung des build-Repositries könnten einige neue oder geänderte Optionen hinzugefügt oder entfernt worden sein, die nicht in die inkludierte Konfigurationsdatei übernommen werden. Diesen Fall sollte man in der eigenen Konfiguration berücksichtigen und falls erforderlich anpassen.
Natürlich kann man ```$HOME/Build/poky-3.2/build/<machine>/conf/local.conf``` mit eigenen Anforderungen ändern und als separate Konfigurationsdatei für einen Maschinentyp verwenden. 

#### Musterkonfiguration für bblayers.conf:
> $HOME/build/poky-3.2/build/```<machine>```/conf/bblayers.conf

```bitbake
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  /home/<username>build/poky-3.2/meta \
  /home/<username>/build/poky-3.2/meta-poky \
  /home/<username>/build/poky-3.2/meta-yocto-bsp \
  "
BBLAYERS += " \
			/home/<username>/build/poky-3.2/meta-neutrino \
			/home/<username>/build/poky-3.2/meta-<machine-brand-or-bsp-name> \
			/home/<username>/build/poky-3.2/meta-openembedded/meta-oe \
			"
BBLAYERS += " \
				/home/<username>/build/poky-3.2/meta-python2 \
				"
BBLAYERS += " \
				/home/<username>/build/poky-3.2/meta-qt5 \
				"
```

## Mehr Informationen
Weitere Informationen zum Yocto Buildsystem:

* https://docs.yoctoproject.org/3.2.4/index.html
