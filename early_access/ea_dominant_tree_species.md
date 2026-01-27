# Dominante Baumart
In diesem Layer wird deutschlandweit die dominante Baumart pro Pixel dargestellt. Die dominante Baumart ergibt sich aus dem Produkt der Baumartenanteile und entspricht derjenigen Baumartengruppe, die innerhalb eines Pixels den höchsten prozentualen Anteil aufweist.
Der Layer ist als klassifiziertes Raster umgesetzt. Jeder Pixel enthält einen ganzzahligen Rasterwert, der einer Baumartengruppe, der Schattenklasse oder der Bodenklasse zugeordnet ist. Die Zuordnung der Rasterwerte zu den Klassen ist in der folgenden Tabelle dargestellt:

<table>
  <tr>
    <th>Typ</th>
    <th>Baumartengruppe</th>
    <th>Rasterwert</th>
    <th>Abgebildete Arten</th>
  </tr>

  <tr>
    <td rowspan="7">Nadelbäume</td>
    <td>Fichte</td>
    <td>1</td>
    <td>Gemeine Fichte (<i>Picea abies</i>)</td>
  </tr>

  <tr>
    <td>Kiefer</td>
    <td>2</td>
    <td>Gemeine Kiefer (<i>Pinus sylvestris</i>)</td>
  </tr>

  <tr>
    <td rowspan="2">Tanne</td>
    <td rowspan="2">3</td>
    <td>Weißtanne (<i>Abies alba</i>)</td>
  </tr>
  <tr>
    <td>Küstentanne (<i>Abies grandis</i>)</td>
  </tr>

  <tr>
    <td>Douglasie</td>
    <td>4</td>
    <td>Douglasie  (<i>Pseudotsuga menziesii</i>)</td>
  </tr>

  <tr>
    <td rowspan="2">Lärche</td>
    <td rowspan="2">5</td>
    <td>Europäische Lärche  (<i>Larix decidua</i>)</td>
  </tr>
  <tr>
    <td>Japanische Lärche  (<i>Larix kaempferis</i>)</td>
  </tr>
</table>

