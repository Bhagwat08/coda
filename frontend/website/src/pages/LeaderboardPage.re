module Styles = {
  open Css;
  let page =
    style([
      maxWidth(`rem(81.5)),
      paddingLeft(`rem(1.25)),
      paddingRight(`rem(1.25)),
      margin(`auto),
    ]);

  let heroRow =
    style([
      display(`flex),
      marginTop(`rem(6.15)),
      flexDirection(`column),
      justifyContent(`spaceBetween),
      alignItems(`center),
      media(Theme.MediaQuery.tablet, [flexDirection(`row)]),
    ]);

  let header =
    style([
      display(`flex),
      flexDirection(`column),
      width(`percent(100.)),
      color(Theme.Colors.slate),
      textAlign(`center),
      margin2(~v=rem(3.5), ~h=`zero),
    ]);

  let heroText =
    merge([header, style([maxWidth(`px(500)), textAlign(`left)])]);

  let heroH3 =
    merge([
      Theme.H3.basic,
      style([
        textAlign(`left),
        fontWeight(`semiBold),
        color(Theme.Colors.marine),
      ]),
    ]);

  let buttonRow = style([display(`flex), flexDirection(`row)]);

  let heroLeft = style([maxWidth(`rem(38.))]);
  let heroRight = style([display(`flex), flexDirection(`column)]);
  let flexColumn =
    style([
      display(`flex),
      flexDirection(`column),
      justifyContent(`center),
    ]);

  let heroLinks = style([padding2(~v=`rem(0.), ~h=`rem(6.0))]);
};

module StatisticsRow = {
  module Styles = {
    open Css;
    let statistic =
      style([
        Theme.Typeface.ibmplexsans,
        textTransform(`uppercase),
        fontSize(`rem(1.0)),
        color(Theme.Colors.saville),
        letterSpacing(`px(2)),
        fontWeight(`semiBold),
      ]);

    let value =
      merge([
        statistic,
        style([
          fontSize(`rem(2.25)),
          marginTop(`px(10)),
          textAlign(`center),
        ]),
      ]);
    let flexRow =
      style([
        display(`flex),
        flexDirection(`row),
        justifyContent(`spaceBetween),
      ]);
    let flexColumn =
      style([
        display(`flex),
        flexDirection(`column),
        justifyContent(`center),
      ]);
  };
  [@react.component]
  let make = () => {
    <div className=Styles.flexRow>
      <div className=Styles.flexColumn>
        <h2 className=Styles.statistic> {React.string("Participants")} </h2>
        <p className=Styles.value> {React.string("456")} </p>
      </div>
      <div className=Styles.flexColumn>
        <h2 className=Styles.statistic> {React.string("Blocks")} </h2>
        <p className=Styles.value> {React.string("123")} </p>
      </div>
      <div className=Styles.flexColumn>
        <h2 className=Styles.statistic>
          {React.string("Genesis Members")}
        </h2>
        <p className=Styles.value> {React.string("121")} </p>
      </div>
    </div>;
  };
};

module HeroText = {
  [@react.component]
  let make = () => {
    <div>
      <p className=Styles.heroH3>
        {React.string(
           "Coda rewards community members with testnet points* for completing challenges \
           that contribute to the development of the protocol.",
         )}
      </p>
      <p className=Theme.Body.basic>
        {React.string(
           "*Testnet Points (abbreviated 'pts') are designed solely to track contributions \
           to the Testnet and Testnet Points have no cash or other monetary value. \
           Testnet Points are not transferable and are not redeemable or exchangeable \
           for any cryptocurrency or digital assets. We may at any time amend or eliminate Testnet Points.",
         )}
      </p>
    </div>;
  };
};

[@react.component]
let make = () => {
  <Page title="Testnet Leaderboard">
    <Wrapped>
      <div className=Styles.page>
        <div className=Styles.heroRow>
          <div className=Styles.heroLeft>
            <h1 className=Theme.H1.basic>
              {React.string("Testnet Leaderboard")}
            </h1>
            <Spacer height=4.3 />
            <StatisticsRow />
            <HeroText />
          </div>
          <div className=Styles.heroRight>
            <div className=Styles.buttonRow>
              <Button
                link=""
                label="Current Challenges"
                bgColor=Theme.Colors.jungle
                bgColorHover=Theme.Colors.clover
              />
              <Spacer width=2.0 />
              <Button
                link=""
                label="Genesis Program"
                bgColor=Theme.Colors.jungle
                bgColorHover=Theme.Colors.clover
              />
            </div>
            <Spacer height=4.8 />
            <div className=Styles.heroLinks>
              <div className=Styles.flexColumn>
                <Next.Link href="">
                  <a className=Theme.Link.basic>
                    {React.string("Leaderboard FAQ")}
                  </a>
                </Next.Link>
                <Next.Link href="">
                  <a className=Theme.Link.basic>
                    {React.string("Discord #Leaderboard Channel")}
                  </a>
                </Next.Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Wrapped>
  </Page>;
};