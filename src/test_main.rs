fn main() {
    eprintln!("TEST: Binary is working!");
    println!("TEST: stdout also works!");
    std::io::Write::flush(&mut std::io::stderr()).unwrap();
    std::io::Write::flush(&mut std::io::stdout()).unwrap();
    eprintln!("TEST: About to exit");
}

