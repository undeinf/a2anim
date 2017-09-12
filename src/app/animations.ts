import {transition, trigger, style, animate, state, keyframes} from '@angular/animations'

export let slide = trigger('slide', [
    transition(':enter', [
        style({transform: 'translateX(-10px)'}),
        animate(500)
    ]),
    transition(':leave', [
        //animate(500,style({transform: 'translateX(-100%)'}))
        //animate('0.5s ease-in',style({transform: 'translateX(-100%)'}))
        //animate('0.5s cubic-bezier(.61, .29, .07, 1.02)',style({transform: 'translateX(-100%)'}))
        animate('0.5s ease-out', keyframes([
            style({
                offset: 0.2,
                opacity: 1,
                transform: 'translateX(20px)'
            }),
            style({
                offset: 1,
                opacity: 0,
                transform: 'translateX(-100%)'
            })
        ]))
    ])
]);

export let fade = trigger('fade',[
    state('void', style({opacity: 0})),
    transition(':enter, :leave', [
      animate(2000)
    ])
  ]);
