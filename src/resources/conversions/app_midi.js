const fs = require('fs');

var cur_offset = 0

var final_data = []

var offsets = [-0.5,-1,1,0,0];
var files = [0,1,2,3,4]

for(var i = 0; i < 5; i++) {
  var data = fs.readFileSync('../kpsk_data/kpsk_'+files[i]+'_midi.json');
  var json_data = JSON.parse(data);
  
  var song_data = json_data["song_data"]

  var final_beat = 0
  
  for(var note in song_data) {
    song_data[note]["beat"] += cur_offset
    final_data.push(song_data[note])
    final_beat = song_data[note]["beat"]
  }

  cur_offset = final_beat + offsets[i]
}

to_write = {"name":"Full", "song_data":final_data}

fs.writeFile('kpsk_5_midi.json', JSON.stringify(to_write, null, 2),  function(err) {
  if (err) {
     return console.error(err);
  }
  
  console.log("Data written successfully!");
});