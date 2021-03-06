$.fn.simplemde = function() {
  $.each($(this), function(_, value) {
    return new SimpleMDE({
      autoDownloadFontAwesome: false,
      element: value,
      toolbar: [
        "bold", "italic", "heading", "|",
        "quote", "unordered-list", "ordered-list", "table", "|",
        "link", "image", "|",
        "preview"
      ],
      status: false,
      previewRender: function(plainText) {
        var res;
        $.ajax({
          async: false,
          url: "/markdown_preview",
          method: "post",
          data: {"markdown": plainText}
        }).done(function(data) {
          res = data;
        });
        return res;
      },
      forceSync: true,
      spellChecker: false
    });
  });
};

var ready = function() {
  $('.selectpicker').selectpicker();

  $(".form_datetime").datetimepicker({
  format: 'dd-mm-yyyy hh:ii',
  weekStart: 1,
  language: 'fr',
  startDate: '+0d',
  minView: 1,
  maxView: 2,
  icons: {
    time: "fa fa-clock-o",
    date: "fa fa-calendar",
    up: "fa fa-arrow-up",
    down: "fa fa-arrow-down"
    }
  });
  
  $.fn.datetimepicker.dates.fr = {
    days: ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"],
    daysShort: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"],
    daysMin: ["D", "L", "Ma", "Me", "J", "V", "S", "D"],
    months: ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"],
    monthsShort: ["Jan", "Fev", "Mar", "Avr", "Mai", "Jui", "Jul", "Aou", "Sep", "Oct", "Nov", "Dec"],
    today: "Aujourd'hui",
    suffix: [],
    meridiem: ["am", "pm"],
    weekStart: 1,
    format: "dd/mm/yyyy"
  };
  
  // Tooltip
  $('[data-toggle=tooltip]').tooltip();

  $('[data-toggle=popover]').popover();

  $('.elastic').elastic();

  $('.simplemde').simplemde();
};


var play_stepmania_song = function(song_id){
  var song = document.getElementById(song_id);
  if(song.paused){
    $('.music_stepmania').each(function(){
      if(!this.paused){this.pause();}
    });
    $('.fa-pause').addClass('fa-play');
    $('.fa-pause').removeClass('fa-pause');
  
    song.play();
    $('#icon_' + song_id).addClass('fa-pause');
    $('#icon_' + song_id).removeClass('fa-play');
  }else{
     $('.music_stepmania').each(function(){
      if(!this.paused){this.pause();}
    });
    $('.fa-pause').addClass('fa-play');
    $('.fa-pause').removeClass('fa-pause');
  }
};

$(document).ready(ready);
$(document).on('page:load', ready);

$(document).ready(function() {
  var isLoadingNextPage = false;  // keep from loading two pages at once
  var lastLoadAt = null;          // when you loaded the last page
  var minTimeBetweenPages = 100; // milliseconds to wait between loading pages
  var loadNextPageAt = 400;      // pixels above the bottom

  var waitedLongEnoughBetweenPages = function() {
    return lastLoadAt == null || new Date() - lastLoadAt > minTimeBetweenPages;
  };

  var approachingBottomOfPage = function() {
    return document.documentElement.clientHeight +
        $(document).scrollTop() > $(document).height() - loadNextPageAt;
  };

  var nextPage = function() {
    var viewMore = $('#view-more'); // tag containing the "View More" link
    var url = viewMore.find('a').attr('href');

    if (isLoadingNextPage || !url)
      return;

    viewMore.addClass('loading');
    isLoadingNextPage = true;
    lastLoadAt = new Date();

    $.ajax({
      url: url,
      method: 'GET',
      dataType: 'script',
      success: function() {
        viewMore.removeClass('loading');
        isLoadingNextPage = false;
        lastLoadAt = new Date();
      }
    });
  };

  // watch the scrollbar
  $(window).scroll(function() {
    if (approachingBottomOfPage() && waitedLongEnoughBetweenPages()) {
      nextPage();
    }
  });

  $(document).on("click", "#view-more a", function(e) {
    nextPage();
    e.preventDefaults();
  });
});

