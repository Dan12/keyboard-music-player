const fs = require('fs');

var data = fs.readFileSync('eq_midi.json');
var json_data = JSON.parse(data);

for(var i = 0; i < json_data["data"].length; i++) {
  var song = json_data["data"][i];
  var to_write = {
    name: song["name"],
    song_data: JSON.parse(song["song_data"])
  }
  fs.writeFile('eq_midi_'+i+'.json', JSON.stringify(to_write, null, 2),  function(err) {
    if (err) {
       return console.error(err);
    }
    
    console.log("Data written successfully!");
  });
} 