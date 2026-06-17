import { Header } from "@/components/header"
import HeroDemo from "@/components/hero-12"
import Logos03 from "@/components/logos-03"
import Feature03 from "@/components/feature-03"
import Cta1 from "@/components/cta"
import FAQs from "@/components/faq"
import Footer from "@/layout/footer"

export default function Page() {
  return (
    <>
      <Header />
      <main>
        <HeroDemo />
        <Logos03 />
        <Feature03 />
        <Cta1 />
        <FAQs />
      </main>
      <Footer />
    </>
  )
}
