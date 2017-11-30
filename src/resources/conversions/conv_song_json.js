const fs = require('fs');

var data = fs.readFileSync('ghet_old.json');
var json_data = JSON.parse(data);

var export_json = {}
export_json["name"] = json_data["song_name"]
export_json["bpm"] = json_data["bpm"]
export_json["soundpacks"] = []
var mappings = json_data["mappings"]
var holdToPlay = json_data["holdToPlay"]
var linkedAreas = json_data["linkedAreas"]

var next_gid = 0;
for(var j = 0; j < 4; j++) {
  var chain = "chain"+(j+1);
  var pack = mappings[chain]
  var htp = holdToPlay[chain]
  var la = linkedAreas[chain]

  var groups = {}
  for(var i = 0; i < la.length; i++) {
    var gid = next_gid;
    next_gid+=1;
    for(var k = 0; k < la[i].length; k++){
      if (groups[la[i][k]]) {
        groups[la[i][k]].push(gid);
      } else {
        groups[la[i][k]] = [gid];
      }
    }
  }

  var cur_pack = []

  var cur_row = [];
  var cur_col = 0;
  for(var i = 0; i < pack.length; i++) {
    if (cur_col == 12) {
      cur_col = 0;
      cur_pack.push(cur_row);
      cur_row = [];
    }

    var elt = {}
    if(pack[i] != "") {
      elt["pitches"] = [chain+"_wav/"+pack[i]+".wav"]
      elt["hold_to_play"] = htp.includes(i);
      elt["loop"] = false;
      if (groups[i]) {
        elt["groups"] = groups[i];
      } else {
        elt["groups"] = [];
      }
      elt["quantization"] = 0;
    }
    cur_row.push(elt);

    cur_col++;
  }
  if (cur_col == 12) {
    cur_col = 0;
    cur_pack.push(cur_row);
    cur_row = [];
  }

  export_json["soundpacks"].push(cur_pack);
}


fs.writeFile('eq_new.json', JSON.stringify(export_json, null, 2),  function(err) {
  if (err) {
     return console.error(err);
  }
  
  console.log("Data written successfully!");
});