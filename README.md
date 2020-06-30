# synchroniseur
Script bash de synchronisation de dossiers/fichiers.<br/>

<h3>Fichiers</h3>
Le script <i>synchroniseur.sh</i> créér 2 fichiers pour son bon fonctionnement :<br/>
- Le fichier de journal <i>.synchro</i> contient les chemins des répertoires à synchroniser A et B ainsi que l'historique des synchronisations réussies.<br/>
- Le fichier de conflits <i>.journal_conflit</i> contient les conflits qui ont pu survenir lors d'une synchronisation.


<h3>Utilisation</h3>
Il faut commencer par changer les 3 variables qui se trouvent en début de script afin qu'elles correspondent à votre utilisation.<br/>
- <i>chemin_absolu</i> correspond à l'endroit où se trouveront les fichiers de journalisation et de conflit.<br/>
- <i>chemin_branche_A</i> correspond au 1er répertoire à synchroniser.<br/>
- <i>chemin_branche_B</i> correspond au 2ème répertoire à synchroniser.<br/>

<pre><code>#branches à synchroniser
chemin_absolu='/home/nicos/'
chemin_branche_A='/home/nicos/A'
chemin_branche_B='/home/nicos/B'</code></pre>

Ensuite il suffit de lancer le script <i>./synchroniseur.sh</i><br/>

<h3>Fonctionnement</h3>
Le script compare les 2 répertoires (A et B). Je considère ainsi pA un fichier/dossier de A et pB un dossier/fichier de B.<br/>
Pour tout fichier p il effectue les actions suivantes :<br/>
<ul>
  <li>Si pA existe et non pB</li>
  <li>Si pB existe et non pA</li>
</ul>
Dans ce cas le script vous propose un menu de 2 choix, vous pourrez<br/>  
- <b>supprimer</b> le fichier/dossier existant.<br/>
- le <b>synchroniser</b> il sera ainsi créé dans le répertoire où il n'existe pas encore.<br/>
<br/>
<ul>
  <li>Si pA est un dossier et pB un fichier</li>
  <li>Si pA est un fichier et pB un dossier</li>
 </ul>
Dans ce cas le script vous propose un menu de choix, vous pourrez<br/>
- <b>supprimer</b> les 2
- les <b>transformer en fichier</b> (on supprime celui qui est un dossier pour copier/coller le fichier à la place).<br/>
- les <b>transformer en dossier</b> (on supprime celui qui est un fichier pour venir copier/coller récursivement le dossier à la place).<br/>
<br/>
<ul>
  <li>Sinon, si pA et pB sont deux fichiers identiques (taille, droit d'accès, date et heure de dernière modification). la synchronisation est réussie (journalisation dans le fichier <i>.synchro</i>).</li>
  <li>Si pA est conforme au fichier de journal et pB ne l'est pas, pB a été modifié (plus récent), pA est donc supprimé pour être remplacé par pB.</li>
  <li>Si pB est conforme au fichier de journal et pA ne l'est pas, pA a été modifié, pB est donc supprimé pour être remplacé par pA.</li>
</ul><br/>
Le seul conflit qui n'est pas géré c'est lorsque pA et pB sont tous les 2 différents du journal de synchronisation. A ce moment le conflit est écrit dans le fichier <i>.journal_conflit</i>. C'est à vous de le régler manuellement, ainsi vous pouvez décider de la version que vous souhaitez garder entre pA et pB.<br/>


<h3>Auteurs</h3>
Nicolas Soares | ni.soares.pro@gmail.com


