use iced::widget::{button, column, text, Column};
use iced::{Center, Theme};

pub fn main() -> iced::Result {
    iced::application("A cool counter", Model::update, Model::view)
        .theme(theme)
        .run()
}

#[derive(Default)]
struct Model {
    value: i64,
}

#[derive(Debug, Clone, Copy)]
enum Message {
    Increment,
    Decrement,
}

fn theme(state: &Model) -> Theme {
    Theme::KanagawaDragon
}
impl Model {
    fn update(&mut self, message: Message) {
        match message {
            Message::Increment => {
                self.value += 1;
            }
            Message::Decrement => {
                self.value -= 1;
            }
        }
    }

    fn view(&self) -> Column<Message> {
        column![
            column![
                button("+").on_press(Message::Increment),
                text(self.value).size(50),
                button("-").on_press(Message::Decrement)
            ]
            .padding(20)
            .align_x(Center),
            button("-").on_press(Message::Decrement)
        ]
    }
}
