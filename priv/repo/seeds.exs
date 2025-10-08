# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

# "Dataset" from  https://www.20minutes.fr/politique/4177859-20251008-direct-demission-sebastien-lecornu-reforme-retraites-invite-negociations... LOL

alias Roda.Repo
alias Roda.Conversations.{Conversation, Chunk}

insert = fn text ->
  %Ecto.Multi{}
  |> Ecto.Multi.insert(:conversation, fn _ ->
    Conversation.changeset(%{})
  end)
  |> Ecto.Multi.insert(:chunk, fn %{conversation: %{id: id}} ->
    Chunk.changeset(%{
      text: text,
      position: 0,
      conversation_id: id
    })
  end)
  |> Repo.transaction()
end

insert.("""
Macron n'a pas évoqué la dissolution lors de son rendez-vous mardi avec Yaël Braun-Pivet

«Ce qui est sûr c'est que ça ne résoudra rien », est convaincue la présidente de l'Assemblée nationale. « Il ne faut pas déstabiliser nos institutions, soyons lucides, soyons responsables, gardons nos nerfs.
""")

insert.("""
Mathilde Panot « ne croit pas » en un gouvernement socialiste

Interrogée sur BFM TV par Apolline de Malherbe, la députée Mathilde Panot, présidente du groupe LFI à l’Assemblée nationale, « ne croit pas » en un gouvernement socialiste.
""")

insert.("""
Lescure n’est pas contre un Premier ministre de gauche

A la question de savoir si un Premier ministre de gauche lui poserait problème, Roland Lescure, ministre de l’Economie démissionnaire, a répondu sur France Inter : « Non. A une condition quand même, c’est qu’il puisse faire ce qu’on n’a pas réussi à faire depuis un an, c’est-à-dire à trouver une majorité capable de voter un budget. »
""")

insert.("""
Lecornu devrait prendre la parole à 9h30

Le Premier ministre démissionnaire fera une déclaration depuis Matignon, juste avant de recevoir les représentants du Parti socialiste, dans le cadre de ses consultations pour tenter de trouver une issue à la crise politique, a annoncé son entourage.
""")

insert.("""
Olivier Faure revendique toujours un Premier ministre de gauche

Olivier Faure, premier secrétaire du PS, revendique toujours un Premier ministre de gauche, comme il l’affirme sur France Info. « Nous ne serons pas dans la confusion. Le débat [parlementaire] doit avoir lieu sur tous les sujets », a-t-il déclaré avant sa rencontre avec Sébastien Lecornu à 10 heures pendant laquelle il voudra « vérifier » que la suspension de la réforme des retraites, qui serait « un geste important et une avancée pour les salariés », n'est pas « un écran de fumée ». 
« Personne ne considère que je suis le prochain Premier ministre », a-t-il ensuite ajouté.
""")

insert.("""
Pour Mathilde Panot, Olivier Faure se contenterait « des miettes »
A la question de « censurer un gouvernement Faure », Mathilde Panot a répondu à Apolline de Malherbe : « Nous sommes en train de parler de quelque chose qui n’arrivera jamais. La seule manière pour Olivier Faure d’être nommé Premier ministre, c’est de se contenter des miettes d’un pouvoir qui est en décomposition. »

Puis, en listant les choses qu’il ne ferait pas comme abroger la réforme de la retraite, augmenter le SMIC dans ce pays, ne pas remettre de l’argent dans les services publics.
""")

insert.("""
« Le compte à rebours pour Macron est lancé », pour Mathilde Panot

Toujours sur BFM TV, Mathilde Panot, présidente du groupe LFI à l’Assemblée nationale, a déclaré : « La macronie est en train d’essayer de gagner du temps car le compte à rebours pour le départ d’Emmanuel Macron est lancé. Quand vous voyez, à la fois dans son propre camp, et un peu partout, le mot d’ordre du départ du président de la République. Et nous, nous sommes magnanimes, nous lui proposons soit de démissionner soit d’être destitué, nous lui laissons le choix. »
""")

insert.("""
« Il y a une volonté partagée d’avoir un budget avant le 31 décembre », assure Lecornu

Sébastien Lecornu a commencé sa déclaration en assurant qu’il se rendrait à l’Elysée pour présenter au président de la République « des solutions qu’il y a sur la table, si nous arrivons à trouver des solutions. »

« Si on voit beaucoup de choses dans la presse, notamment hier, j’ai des bonnes raisons de vous dire, que parmi les bonnes nouvelles, avec l’ensemble des consultations que j’ai pu avoir […] il y a une volonté d’avoir, pour la France, un budget avant le 31 décembre de cette année », a-t-il assuré. Avant d’ajouter : « Et cette volonté créée un mouvement et une convergence évidemment éloignent la perspective de dissolution », a ajouté Sébastien Lecornu.

Il a ensuite évoqué la « réduction de notre déficit qui est clé » pour « la crédibilité de la signature de la France à l’étranger » et la « capacité à emprunter ». « Tout le monde s’accorde à dire que la cible de déficit publique doit être tenue en dessous de 5 % », a dit le Premier ministre.
""")

insert.("""
« Les ministres qui ont été ministres quelques heures n’auront pas le droit à leurs indemnités », a déclaré Lecornu

Le Premier ministre a voulu terminer sa déclaration sur « un point qui n’est pas que technique » puisqu’il a pu voir qu’un « certain nombre de Français et de Françaises qui se sont émus » : « Il se trouve que les membres du gouvernement lorsqu’ils quittent leurs fonctions ont le droit à trois mois d’indemnités lorsqu’ils n’ont pas de revenus par ailleurs. Il est évident que les ministres qui auront été ministres seulement quelques heures n’auront pas le droit à ces indemnités, j’ai décidé de les suspendre. »

Et de conclure : « On ne peut pas vouloir faire des économies si on ne maintient pas par ailleurs une règle d’exemplarité et de rigueur dans la suite des autres décisions que j’ai pu prendre. »
""")

insert.("""
09h44
La déclaration du Premier ministre est déjà terminée

Elle aura duré moins de cinq minutes. Le Premier ministre a parlé de la Nouvelle-Calédonie, de la situation internationale au Proche-Orient et en Ukraine mais il n'a pas parlé de la réforme des retraites. Il devra s'exprimer de nouveau en fin de journée après les consultations avec la gauche pour voir « quelles concessions elle demande pour garantir une stabilité », « après ou avant » s'être rendu auprès du chef de l'État à l'Élysée.
""")

insert.("""
Mélenchon ne veut pas du PS à Matignon 
Consternant ralliement d'Olivier Faure au sauvetage du système. Cessez d'assimiler son choix personnel aux autres composantes du NFP. LFI n'a rien à voir avec ça.
""")

insert.("""
Le PS reçu par Lecornu

Après son rapide point presse, Sébastien Lecornu reçoit à Matignon la délégation socialiste. Des sujets comme la réforme des retraites et un gouvernement de gauche seront évoqués. Le Premier ministre recevra ensuite les communistes à 11h15 et les écologistes à 12h15.
""")
